# ADR-0009: Live status widget worker lives in the website repo, not here

## Status

Accepted — 2026-05-03 — Supersedes the "Status widget" section of [ADR-0004](ADR-0004-minecraft-server-architecture.md).

## Context

ADR-0004 specified a Cloudflare Worker in this repo (`worker/src/index.js`)
implementing the Minecraft Server List Ping (SLP) protocol directly via
`cloudflare:sockets`, caching results in KV, and exposing
`/status` for the website's `/minecraft` page to fetch.

During the bootstrap of this repo on 2026-05-02, that worker was deployed to
`merric-mc-status.meteoricmetric.workers.dev` and verified live.

**Then we discovered:** the website repo (`MeteoricMetric/MeteoricMetric.github.io`)
already has its own deployed multi-endpoint worker (`merricstrough-now-playing`)
with a `/api/minecraft-status` route. That route:

- Proxies `api.mcstatus.io v2` (simpler than direct SLP implementation)
- Lives next to `/api/now-playing`, `/api/top-tracks`, `/api/twitch-status`
  in a single TS codebase (`worker/src/index.ts` + per-endpoint modules)
- Is consumed by `src/components/MinecraftStatus.astro` via the canonical
  `WORKER_ENDPOINTS.minecraftStatus` constant in `src/data/worker-config.ts`
- Was consolidated into the multi-endpoint shape on 2026-05-02 (the same day
  this repo was bootstrapped — parallel work, neither aware of the other)

The two workers do the same job. Two implementations of the same widget is
worse than one — confusing for future readers, double maintenance, double
deploy paths.

## Decision

**The live status widget worker lives in the website repo.** The worker dir
in this repo (`worker/`) is removed. The redundant `merric-mc-status` worker
and its KV namespace `MC_STATUS_CACHE` are deleted from Cloudflare.

This aligns with master `merricstrough.com/CLAUDE.md` §3.4:
> "The minecraft subdomain page is a static frontend; the server itself is
> operational infrastructure documented in its own repo. Don't conflate them."

**Frontend (site + worker) → website repo. Backend (game server, ops) → this repo.**
Cross-link, don't duplicate.

## Consequences

**Removed from this repo:**
- `worker/` directory (frontend-snippet.astro, src/index.js, wrangler.toml, package.json, package-lock.json)
- `worker-smoke` CI job (no worker to smoke-test here)
- `npm` ecosystem block in `.github/dependabot.yml`
- `worker/*` lines in `.gitignore`

**Removed from Cloudflare:**
- Worker `merric-mc-status`
- KV namespace `MC_STATUS_CACHE` (id: `4d5c25def3c744f5a622ebed6ec85eef`)

**Updated cross-references (this repo):**
- `CLAUDE.md` "Modifying the status worker" task moved out of routine/standard
  lists — it's website-repo work now
- `MINECRAFT-BUILD-GUIDE.md` Phase 6 ("Deploy the worker") replaced with a
  cross-reference to the website repo's worker README
- `docs/CHILD-SAFETY-PRIVACY.md` references to `worker/src/index.js`
  rewritten to point at the website repo's `worker/src/minecraft.ts`
- `README.md` stack-list entry for the Cloudflare Worker rewritten as a
  link to the website repo

**One-time setup that still has to happen** (in the *website* repo) when the
Minecraft server actually goes online in Phase 5:

- Set `MINECRAFT_SERVER_ADDRESS` in `merricstrough-com/worker/wrangler.toml`
  `[vars]` to the playit hostname / port (e.g. `xxx.gl.joinmc.link:25565`)
- `cd merricstrough-com/worker && npx wrangler deploy`

## Alternatives considered

- **Keep both workers** — confusing, double maintenance. Rejected.
- **Make this repo's worker canonical, remove the website's** — moves
  complexity to the wrong repo per master §3.4, and the website's worker
  was the more recent / more architecturally consolidated version.
- **Keep this repo's worker as a fallback** — would rot without CI / use,
  and mcstatus.io has been reliable. The original SLP-direct implementation
  remains in git history if ever needed (commits before this ADR landed).

## Lessons

This was preventable: the website repo's worker README and the merric-minecraft
build guide were written in parallel without either referring to the canonical
worker location. Master CLAUDE.md cross-references existed but didn't cover
"worker source of truth" specifically. Going forward:

- New ADRs that touch the cross-repo seam (frontend ↔ infra) should
  explicitly name which repo owns the artifact
- Master CLAUDE.md should mention: "live data widgets are website-repo
  workers; infra repos consume the contract, don't reimplement it"

---

*Author: Shane + Claude during 2026-05-03 bootstrap session.*
