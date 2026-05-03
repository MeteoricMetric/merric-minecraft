# ADR-0004: MeteoricCraft Minecraft server architecture

## Status
Accepted — 2026-05-02 (revised in v1.1 with sibling ADRs 0005-0008)

> This ADR was originally the master architecture decision. As of v1.1, several of its sub-decisions have been promoted to dedicated sibling ADRs for the level of detail they deserve:
> - **Network exposure** → [ADR-0005](ADR-0005-network-exposure-strategy.md)
> - **Backup and restore** → [ADR-0006](ADR-0006-backup-restore-strategy.md)
> - **Plugin governance** → [ADR-0007](ADR-0007-plugin-governance.md)
> - **Child-safety and privacy** → [ADR-0008](ADR-0008-child-safety-privacy-boundaries.md)
>
> This ADR remains the canonical entry point for the overall stack decision. The siblings extend it.

## Context

Merric (age 13) wanted a "badass" Minecraft server his friends could join. His friends are on Bedrock (phones, consoles); he plays both. We host on Shane's home workstation (hardware/OS specifics in `CLAUDE.local.md`). The server should:

- Be reachable by Bedrock and Java players on the same world
- Run 24/7 without manual intervention
- Not expose Shane's home IP to public Minecraft players
- Survive workstation reboots, plugin updates, and version upgrades
- Provide a live status widget on `merricstrough.com/minecraft`
- Be recoverable from automated backups
- Be ops-able by Merric without Shane's intervention for routine tasks
- Match the engineering rigor of the rest of the merricstrough.com project

## Decision

### Server software: **Paper 1.21.11** (NOT 26.1)

Mojang changed their versioning scheme in 2026 (1.21.11 → 26.1). Geyser/Floodgate compatibility broke on Paper 26.1.x as of April 2026 (GeyserMC issue #6297). Paper 1.21.11 is the latest version Geyser officially supports, and the entire plugin ecosystem is mature for it. We accept being one minor version behind in exchange for a reliable cross-platform stack.

Revisit when: Geyser officially supports 26.x and the major plugins (LuckPerms, EssentialsX, BlueMap, etc.) all confirm 26.x compatibility.

### Cross-play: **Geyser-Spigot + Floodgate**

Bedrock-native servers (PocketMine-MP, NukkitX) have an immature plugin ecosystem. A Java server with Geyser+Floodgate gives us the entire Bukkit/Paper plugin universe while letting Bedrock players connect natively. Floodgate handles authentication so Bedrock friends don't need Java accounts. Tradeoff: 2% more setup complexity, occasional UI quirks translating Java menus to Bedrock.

### Containerization: **Docker via `itzg/minecraft-server`**

The `itzg/minecraft-server:java21` image is the community-standard. Handles Paper version pinning, plugin auto-download via env vars (Modrinth + Spiget + direct URLs), modern JVM flags (we use `USE_MEOWICE_FLAGS` for Java 21+ tuning, not the legacy Aikar's flags which were tuned for Java 8/11), healthchecks, EULA acceptance. Containerization gives us:

- Clean separation from Shane's other workstation processes
- Easy upgrade path (pull new image, recreate container)
- Resource caps (8GB RAM / 4 CPU limit prevents runaway plugins from tanking the workstation)
- Identical reproducibility on a different machine when we eventually move to Colorado
- Plugin definitions in `docker-compose.yml` (infrastructure-as-code, version-controlled)

Alternatives considered:
- **systemd unit** with direct Paper install — more "native" but less portable, harder to upgrade, no resource isolation
- **PaperMC native installer** — same downsides as systemd
- **Forge/Fabric server** — wrong tool; Merric wants plugins, not mods

### Network exposure: **playit.gg tunnel**

Shane's residential IP is the single biggest doxxing risk for a kids' server. Port forwarding exposes him to DDoS, ISP suspension, and pivot attacks if the server is ever exploited. playit.gg's anycast edge absorbs all of that.

Tradeoffs we accept:
- +30-50ms latency (imperceptible in survival gameplay)
- Single point of failure if playit has an outage (mitigated by: it's a kids' server, not life-critical)
- Trusting playit with traffic metadata (mitigated by: 2FA on the account, agent in its own container)
- Free tier uses shared anycast IP (good enough; can upgrade to dedicated IP if needed)

This was deliberated extensively earlier in the project. Decision criteria recap (April 2026):

1. Florida hurricane country + planned Colorado relocation — playit means zero reconfig on IP/ISP changes
2. Kids' servers attract grief and booters; blast radius of home IP leak is way worse than +30ms
3. The 5090 rig runs real work (Elevare Beats, dev) — can't have Minecraft DDoS eating residential bandwidth

### Plugin loadout: 13-plugin "badass starter pack"

Tier-1 (cross-platform & infrastructure):
- **Geyser-Spigot** — Bedrock protocol bridge
- **Floodgate** — Bedrock account auth bypass
- **ViaVersion / ViaBackwards** — let players on different Java versions connect

Tier-2 (admin & permissions):
- **LuckPerms** — modern permission system
- **EssentialsX** — homes, warps, /tpa, kits, mute, basic economy
- **CoreProtect** — block logging + grief rollback
- **WorldEdit + WorldGuard** — region protection + admin building

Tier-3 (quality of life):
- **Multiverse-Core** — multiple worlds (room to grow)
- **DiscordSRV** — chat bridge to Discord
- **Vault** — economy/permissions API bridge
- **BlueMap** — live web map
- **Chunky** — async chunk pre-generation (eliminates new-area lag)
- **Spark** — performance profiler

Deliberately NOT in v1 (deferred):
- Citizens NPCs, MythicMobs, custom minigames — survival core first, complexity later
- Towny/Factions — overkill for a friend group of 20
- Anti-cheat plugins like NoCheatPlus — usually cause more false positives than they prevent grief

### Backups: **restic**, daily, 7-day rolling

restic gives us:
- Encrypted backups by default
- Deduplication (worlds barely change day-to-day; storage stays small)
- Easy restore (`restic restore <snapshot-id>`)
- Local + cloud target options (we're starting local; documented path to Backblaze B2 later)

Atomic snapshots via `rcon save-off` + `save-all flush` before snapshot, then `save-on` immediately after. Backup runs at 3am via cron.

### Status widget: **Cloudflare Worker** ~~querying via SLP protocol~~

> **Superseded 2026-05-03 by [ADR-0009](ADR-0009-status-widget-worker-location.md).**
> The worker lives in the website repo (`MeteoricMetric/MeteoricMetric.github.io`),
> not here, and proxies `api.mcstatus.io` instead of implementing SLP directly.
> Original rationale below kept for historical context.

Mirrors the architectural pattern already established by the Spotify Now Spinning widget (per ADR-0001). Worker:
- Polls the server every minute via Minecraft Server List Ping protocol
- Caches result in Cloudflare KV for 60s
- Returns JSON to `merricstrough.com/minecraft`

Frontend uses the same component conventions as the rest of the site (Astro, OKLCH tokens, view transitions, `prefers-reduced-motion` support, WCAG AA contrast). Replaces the current `/minecraft` stub.

### DNS: **playit.gg + clean Porkbun aliases**

- `mc.merricstrough.com` → CNAME → playit Java tunnel hostname (Java players)
- Bedrock requires port-aware addressing; SRV record + raw fallback documented
- `map.merricstrough.com` → BlueMap web UI (separate playit TCP tunnel)

## Alternatives considered and rejected

- **Realms** — Mojang's official hosting. Easy, but limited plugin support, no Bedrock+Java in one world without workarounds, monthly fee, no real ops experience for Merric to learn from.
- **Aternos** — free hosted Minecraft. Forces ads, rate-limits plugins, server sleeps when no one's online (15-30s wake), Bedrock support patchy. Below the engineering bar of the rest of the project.
- **Paid hosting (Shockbyte, Bisect)** — $10-15/mo, fine performance, but learning value is near zero. The whole point is Merric learning real infrastructure.
- **Self-hosted on a VPS (DigitalOcean, Hetzner)** — would work, but the home workstation has far more capacity than a $5 VPS for this workload. No reason to add monthly cost.
- **Tailscale-only** — ruled out by user explicitly. Friends-of-friends would need Tailscale installed; awkward for kids.
- **Direct port forwarding** — Shane's home IP doxxing risk is unacceptable for a server that's specifically going to host kids who might fight.
- **Cloudflare Spectrum** — would proxy Minecraft TCP/UDP at scale, but enterprise pricing makes it impractical for a personal server.

## Consequences

### Good
- Real engineering project Merric can learn from for years (Docker, DNS, Cloudflare Workers, restic, RCON, plugin permissions)
- Bedrock-friendly so all his actual friends can join from phones
- Home IP stays private; DDoS risk absorbed by playit's edge
- Backups are real, automated, and tested
- Status widget makes the website feel alive, not static
- Architecture is portable — one `git clone && docker compose up` away from running on any machine
- Skills transfer to any future server, app, or service he builds

### Bad / accepted tradeoffs
- One Mojang version behind on the Minecraft side (waiting for Geyser)
- +30-50ms latency through playit (imperceptible for survival, possibly noticeable in PvP)
- Cloudflare and playit are two third-party dependencies (mitigated by both being free, replaceable, and well-established)
- More moving parts than a vanilla single-server install (mitigated by `ops.sh` and a kid-friendly cheat sheet)

### Things to revisit
- Migrate to Paper 26.x once Geyser officially supports it (likely Q3 2026)
- Add Modrinth-based plugin sourcing for newer plugins
- Add Simple Voice Chat (Modrinth project: `voicechat`) once friend group requests it
- Promote the `/minecraft` page to its own subdomain repo (`merric-minecraft-site`) when content justifies extraction (per merricstrough.com CLAUDE.md §3.3)
- Off-site backup target (B2) once local backup history is established
- Consider adding the server to the family graph JSON-LD as a `Service` schema once it has a real URL identity

## References

- Build guide: `merric-minecraft/MINECRAFT-BUILD-GUIDE.md` (in the merric-minecraft repo)
- Sibling ADRs (v1.1):
  - [ADR-0005](ADR-0005-network-exposure-strategy.md) — Network exposure strategy
  - [ADR-0006](ADR-0006-backup-restore-strategy.md) — Backup and restore strategy
  - [ADR-0007](ADR-0007-plugin-governance.md) — Plugin governance
  - [ADR-0008](ADR-0008-child-safety-privacy-boundaries.md) — Child-safety and privacy boundaries
- Earlier deliberation: see project conversation history, April 18 2026 — Java vs Bedrock, port forward vs tunnel
- itzg/minecraft-server docs: https://docker-minecraft-server.readthedocs.io
- Geyser supported versions: https://geysermc.org/wiki/geyser/supported-versions/
- playit.gg docs: https://playit.gg/

---

*Decision recorded by: Shane Strough, Claude*
*Implementation: Shane + Merric, May 2026*
*Revised: v1.1 — promoted detailed sub-decisions to sibling ADRs*
