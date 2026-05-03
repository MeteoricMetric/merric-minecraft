/**
 * MeteoricCraft Status Worker
 *
 * Polls the Minecraft server via the Server List Ping protocol every 60s,
 * caches the result in KV, and returns JSON to the website.
 *
 * Mirrors the architectural pattern of the Spotify "Now Spinning" worker
 * (per merricstrough.com ADR-0001 — Cloudflare Workers as the canonical
 * pattern for live-data widgets).
 *
 * Deployment:
 *   npx wrangler kv namespace create MC_STATUS_CACHE
 *   (paste the namespace ID into wrangler.toml)
 *   npx wrangler deploy
 *
 * Usage from frontend:
 *   fetch('https://merric-mc-status.<your>.workers.dev/status')
 *
 * Returns:
 *   {
 *     online: boolean,
 *     players: { online: number, max: number, sample: string[] },
 *     motd: string,
 *     version: string,
 *     latency_ms: number,
 *     cached_at: string (ISO 8601)
 *   }
 */

const CACHE_TTL_SECONDS = 60;
const CACHE_KEY = "mc:status:v1";

// Default fallback if env not set (mostly for safety)
const DEFAULT_HOST = "mc.merricstrough.com";
const DEFAULT_PORT = 25565;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // CORS — only allow merricstrough.com and local dev
    const origin = request.headers.get("Origin") || "";
    const allowedOrigins = [
      "https://merricstrough.com",
      "https://www.merricstrough.com",
      "http://localhost:4321",
      "http://localhost:3000",
    ];
    const corsOrigin = allowedOrigins.includes(origin) ? origin : "https://merricstrough.com";

    const corsHeaders = {
      "Access-Control-Allow-Origin": corsOrigin,
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Max-Age": "86400",
      "Vary": "Origin",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname !== "/status" && url.pathname !== "/") {
      return new Response("Not Found", { status: 404, headers: corsHeaders });
    }

    // Try cache first
    const cached = await env.MC_STATUS_CACHE.get(CACHE_KEY);
    if (cached) {
      return new Response(cached, {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
          "X-Cache": "HIT",
        },
      });
    }

    // Cache miss — query the server
    const host = env.MC_HOST || DEFAULT_HOST;
    const port = parseInt(env.MC_PORT || DEFAULT_PORT, 10);

    let result;
    try {
      result = await pingMinecraftServer(host, port);
    } catch (err) {
      result = {
        online: false,
        error: err.message,
        host,
        port,
      };
    }

    result.cached_at = new Date().toISOString();
    const payload = JSON.stringify(result);

    // Cache it (even if offline, so we don't hammer a down server)
    ctx.waitUntil(
      env.MC_STATUS_CACHE.put(CACHE_KEY, payload, { expirationTtl: CACHE_TTL_SECONDS })
    );

    return new Response(payload, {
      status: 200,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
        "X-Cache": "MISS",
      },
    });
  },
};

/**
 * Implement the Minecraft Server List Ping protocol (modern, post-1.7).
 * Cloudflare Workers support outbound TCP via `connect()` from cloudflare:sockets.
 *
 * Protocol reference: https://wiki.vg/Server_List_Ping
 * 1. Send Handshake (state = 1, status request)
 * 2. Send Status Request
 * 3. Read Status Response (JSON)
 * 4. Send Ping
 * 5. Read Pong (for latency)
 */
async function pingMinecraftServer(host, port) {
  const { connect } = await import("cloudflare:sockets");
  const startTime = Date.now();

  const socket = connect({ hostname: host, port }, { allowHalfOpen: false });
  const writer = socket.writable.getWriter();
  const reader = socket.readable.getReader();

  try {
    // ── Handshake ─────────────────────────────────────────────────────────
    const handshake = buildHandshakePacket(host, port, 770); // 770 = 1.21.x protocol
    await writer.write(handshake);

    // ── Status Request ─────────────────────────────────────────────────────
    await writer.write(new Uint8Array([0x01, 0x00])); // length=1, packetId=0

    // ── Read Status Response ───────────────────────────────────────────────
    const responseBuffer = await readPacket(reader);
    const json = parseStatusResponse(responseBuffer);

    const latency = Date.now() - startTime;

    return {
      online: true,
      players: {
        online: json.players?.online ?? 0,
        max: json.players?.max ?? 20,
        sample: (json.players?.sample || []).map((p) => p.name).slice(0, 12),
      },
      motd: extractMotd(json.description),
      version: json.version?.name ?? "unknown",
      protocol: json.version?.protocol ?? null,
      favicon: json.favicon ?? null,
      latency_ms: latency,
      host,
      port,
    };
  } finally {
    try { await writer.close(); } catch { /* ignore */ }
    try { await reader.cancel(); } catch { /* ignore */ }
    try { await socket.close(); } catch { /* ignore */ }
  }
}

// ── Protocol helpers ──────────────────────────────────────────────────────

function buildHandshakePacket(host, port, protocolVersion) {
  const hostBytes = new TextEncoder().encode(host);

  const fields = [
    encodeVarInt(0x00),                  // packet ID
    encodeVarInt(protocolVersion),       // protocol version
    encodeVarInt(hostBytes.length),      // host length
    hostBytes,                           // host
    new Uint8Array([(port >> 8) & 0xff, port & 0xff]), // port (big-endian uint16)
    encodeVarInt(1),                     // next state: 1 = status
  ];

  const payload = concatBytes(fields);
  return concatBytes([encodeVarInt(payload.length), payload]);
}

function encodeVarInt(value) {
  const bytes = [];
  while (true) {
    if ((value & ~0x7f) === 0) {
      bytes.push(value);
      return new Uint8Array(bytes);
    }
    bytes.push((value & 0x7f) | 0x80);
    value >>>= 7;
  }
}

async function readVarInt(reader, leftover) {
  let value = 0;
  let position = 0;
  const bytes = leftover ? Array.from(leftover) : [];
  let idx = 0;

  while (true) {
    if (idx >= bytes.length) {
      const { value: chunk, done } = await reader.read();
      if (done) throw new Error("Connection closed during VarInt read");
      bytes.push(...chunk);
    }
    const byte = bytes[idx++];
    value |= (byte & 0x7f) << position;
    if ((byte & 0x80) === 0) break;
    position += 7;
    if (position >= 32) throw new Error("VarInt too large");
  }

  return { value, consumed: idx, leftover: new Uint8Array(bytes.slice(idx)) };
}

async function readPacket(reader) {
  // Read packet length VarInt
  const lengthResult = await readVarInt(reader, new Uint8Array());
  const totalLen = lengthResult.value;
  let buffer = lengthResult.leftover;

  while (buffer.length < totalLen) {
    const { value: chunk, done } = await reader.read();
    if (done) throw new Error("Connection closed during packet read");
    const merged = new Uint8Array(buffer.length + chunk.length);
    merged.set(buffer, 0);
    merged.set(chunk, buffer.length);
    buffer = merged;
  }

  return buffer.slice(0, totalLen);
}

function parseStatusResponse(buffer) {
  // packet ID (VarInt) + JSON length (VarInt) + JSON string
  let offset = 0;
  const packetId = decodeVarIntAt(buffer, offset);
  offset += packetId.bytes;
  const jsonLen = decodeVarIntAt(buffer, offset);
  offset += jsonLen.bytes;

  const jsonBytes = buffer.slice(offset, offset + jsonLen.value);
  const jsonStr = new TextDecoder().decode(jsonBytes);
  return JSON.parse(jsonStr);
}

function decodeVarIntAt(buffer, start) {
  let value = 0;
  let position = 0;
  let bytes = 0;
  while (true) {
    const byte = buffer[start + bytes];
    bytes++;
    value |= (byte & 0x7f) << position;
    if ((byte & 0x80) === 0) break;
    position += 7;
    if (position >= 32) throw new Error("VarInt too large");
  }
  return { value, bytes };
}

function concatBytes(arrays) {
  const total = arrays.reduce((sum, a) => sum + a.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const a of arrays) {
    out.set(a, offset);
    offset += a.length;
  }
  return out;
}

function extractMotd(description) {
  if (!description) return "";
  if (typeof description === "string") return description;
  // Modern servers send a JSON Chat component
  if (description.text) return description.text + extractFromExtra(description.extra);
  return extractFromExtra(description.extra);
}

function extractFromExtra(extra) {
  if (!Array.isArray(extra)) return "";
  return extra.map((e) => (typeof e === "string" ? e : e.text || "")).join("");
}
