# CLAUDE.md — merric-minecraft

> **Cross-project doctrine:** this project follows the one engineering law — reason from
> first principles on the moat, ride the paved road on the scaffolding, never hand back a
> blocker you haven't tried to break yourself, and verify against ground truth, not memory.
> It lives in [`../AI_CODING_DOCTRINE.md`](../AI_CODING_DOCTRINE.md) (root of `projects_root`)
> and applies here.

> Companion file to the master `CLAUDE.md` in `merricstrough.com`. This one is scoped to infrastructure operations.

## Project

**MeteoricCraft** Minecraft server. Paper 1.21.11 + Geyser + Floodgate, Docker Compose, playit.gg tunnel, hosted on Shane's home workstation (hardware/OS specifics in `CLAUDE.local.md`).

- Owner: Merric Strough (`MeteoricMetric`)
- Co-pilot: Shane Strough (`ShaneS08`)
- Repo: `github.com/MeteoricMetric/merric-minecraft`
- Status widget: `merricstrough.com/minecraft`
- Architecture rationale: `docs/decisions/ADR-0004-minecraft-server-architecture.md` (in the website repo)

## Operating principles

This repo inherits the operating principles from `merricstrough.com/CLAUDE.md` Section 1. The infrastructure-specific application:

- **First-principles thinking** → don't add plugins because "people use them"; add them when there's a real need
- **Ruthless prioritization** → ship a working server first; add nice-to-haves only after Tier-1 (cross-play + ops + backups) is solid
- **Paranoid security** → home IP never exposed, RCON localhost-only, secrets gitignored, perimeter or compensating-controls (per server-format ADR) enforced
- **Documentation as deliverable** → every config decision lives in this repo or in an ADR; nothing is tribal knowledge
- **Teach while building** → ops scripts are designed for Merric to read, understand, and eventually modify

## Coding & config standards

### docker-compose.yml
- Use named services with `container_name:` set explicitly
- Bind ports to `127.0.0.1:` unless deliberately public — playit handles external
- Resource limits explicit (`deploy.resources.limits`)
- Healthchecks on every long-running service
- Comments above every non-obvious env var

### Shell scripts (scripts/*.sh)
- `set -euo pipefail` at the top of every script
- Heredoc-style help text in every user-facing script
- Resolve script-relative paths via `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Source `.env` explicitly; fail fast if required vars are missing
- Log timestamps in ISO-8601 format
- All destructive operations require explicit confirmation typed by user (e.g., "RESTORE")

### .env handling
- Never commit `.env`. Ever.
- `.env.example` IS committed — must stay in sync with required vars
- Every variable in `.env.example` has a comment explaining what it does and how to obtain a value
- Generation commands documented (e.g., `openssl rand -base64 24`)

## Security rules

Inherited from `merricstrough.com/CLAUDE.md` Section 5, with additions:

- **No public ports without playit** — never `0.0.0.0:25565` or unspecified host binding
- **RCON port localhost only** — `127.0.0.1:25575:25575/tcp`, never exposed
- **`ENFORCE_WHITELIST` posture is set by ADR** — the current value (per `docs/decisions/ADR-0010`) is `false`, paired with mandatory compensating controls (CoreProtect, spawn protection, anti-combat-log, Discord moderation). Changing the posture in either direction requires a new ADR superseding the current one
- **`ONLINE_MODE=false` is required for Floodgate** — but mitigated by whitelist + Floodgate auth
- **Plugin URLs pinned where possible** — direct GitHub release URLs over "latest" links for security-critical plugins
- **Secrets handling**:
  - RCON password ≥ 24 base64 chars
  - playit secret key in env var, never in compose file
  - 2FA on playit, GitHub, Cloudflare accounts
- **No untrusted plugins** — only Modrinth, Hangar, official GitHub releases, BukkitDev. No random forum jars.

## Testing

- Manual smoke test before each merge to main:
  - `docker compose config` validates compose file
  - `docker compose up -d` brings stack up cleanly
  - `./scripts/ops.sh status` shows healthy
  - Connect from one Java client + one Bedrock client
  - `./scripts/backup.sh` runs successfully
- After plugin changes:
  - Watch first 5 min of logs for plugin load errors
  - Test that whitelist still enforces
  - Test that LuckPerms permissions still resolve
- After version upgrades:
  - Always backup first
  - Test on a copy of world data if upgrading Paper major version

## When working on this repo

The change-management ladder (RUNBOOK.md §1) defines what's safe at each tier. This Claude Code-specific summary aligns with that ladder.

### Routine tasks (🟢 — no extended process needed)
- Adjusting MOTD
- Updating whitelist
- Adding/removing a single plugin from an already-approved source
- Tweaking resource limits
- Editing rules text on the `/minecraft` page

### Standard tasks (🟡 — plan → implement → review → commit)
- Adding a new plugin (must follow PLUGIN-GOVERNANCE.md §4 install process)
- Updating the backup script
- Adjusting plugin permissions structure (LuckPerms groups)
- Configuring DiscordSRV (new install or routine reconfig)

### Significant tasks (🔴 — research → ADR → human approval → implement)
- Upgrading Paper major version (e.g., 1.21 → 26)
- Switching tunnel provider away from playit
- Changing the Docker host architecture
- Anything touching backup encryption or restoration
- Adding a service that opens new ports
- Enabling DiscordSRV bidirectional chat bridge (also requires CHILD-SAFETY-PRIVACY.md §4.2 preconditions)
- Publishing BlueMap with any non-default settings (markers, live data, etc.)
- Decision to make the server publicly discoverable

## Working with Merric on infrastructure

When Merric is sitting at the keyboard for ops work:

1. **Let him type the commands.** Even when slow. Muscle memory matters.
2. **Explain `set -e`, env vars, and Docker the FIRST time he sees them**, not every time.
3. **Encourage running `--help` on unfamiliar commands** before asking for help.
4. **For destructive operations** (restore, drop, delete), pause and walk through what's about to happen.
5. **When something breaks**, ask "what changed?" before "let me fix it." That's the actual debugging skill.
6. **Celebrate working systems out loud.** "The server's been up for 3 days. That's because the healthcheck restart policy worked. You wrote that."

## Live plugin manifest (31 plugins as of v1.3)

Source-of-truth: `docker-compose.yml` `PLUGINS` (direct URLs) + `MODRINTH_PROJECTS`. Direct-URL plugins are pinned for reproducibility; Modrinth ones auto-resolve to the latest 1.21.11-compatible build.

**Direct URLs (5)** — Geyser, Floodgate (cross-play), Vault (1.7.3), EssentialsX core (2.21.2), EssentialsXSpawn (2.21.2). CoreProtect (23.1) is also a direct manual JAR drop into `data/plugins/` (no working programmatic source yet).

**Modrinth (24)** — viaversion, viabackwards, luckperms, worldedit, worldguard, chunky, squaremap, multiverse-core, discordsrv, crazycrates, quickshop-hikari, ndailyrewards, anti_combatlog, tab-was-taken, decentholograms, auraskills, duels, auctionhouseplus, villagershop, mythicmobs, griefprevention, bluemap, placeholderapi, votespeed, simplertp.

**Paper-bundled (1)** — spark (Paper 1.21.11+ ships it natively; do NOT install separately or you get a remap conflict).

Plugin governance + tier classification: `docs/PLUGIN-GOVERNANCE.md`.

## Cross-references

- Master CLAUDE.md (sets all conventions): https://github.com/MeteoricMetric/meteoricmetric.github.io/blob/main/CLAUDE.md
- **Operational policy docs in this repo:**
  - `docs/RUNBOOK.md` — change-management ladder, common incidents, restore drills, custom-boss commands, crate-key issuance, GriefPrevention claim flow
  - `docs/PLUGIN-GOVERNANCE.md` — approved sources, full plugin manifest, install/update/remove
  - `docs/CHILD-SAFETY-PRIVACY.md` — public/private taxonomy, identity, moderation
  - `docs/MERRIC-OPS-MANUAL.md` — kid-readable day-to-day ops guide for Merric (admin commands, boss spawning, crate-key issuance, when-to-ask-Shane)
  - `docs/PLAYER-GUIDE.md` — public player-facing guide for friends + their parents (how to connect, what to do, rules, a-note-for-parents). Suitable for republishing on `merricstrough.com/minecraft`.
- **Architectural decisions:**
  - `docs/decisions/ADR-0004` — overall stack
  - `docs/decisions/ADR-0005` — network exposure (playit now, VPS later)
  - `docs/decisions/ADR-0006` — backup and restore (3-2-1, restic, quarterly drills)
  - `docs/decisions/ADR-0007` — plugin governance
  - `docs/decisions/ADR-0008` — child-safety and privacy
  - `docs/decisions/ADR-0009` — status widget worker lives in website repo
  - `docs/decisions/ADR-0010` — public economy-server format (replaces whitelist with compensating controls)
- Status widget: implemented in the website repo's worker (`MeteoricMetric/MeteoricMetric.github.io` → `worker/src/minecraft.ts`). This repo does NOT contain widget code — see ADR-0009.

---

*v1.3 — 2026-05-08 — Round-3-through-5 documentation pass: plugin manifest expanded to 31 (was 13 in v1.1); ADR-0010 (public economy server format) landed and now referenced inline; new docs MERRIC-OPS-MANUAL.md and PLAYER-GUIDE.md added; cross-references updated; CHANGELOG v1.3.0 records the build/config arc end-to-end.*
*v1.2 — 2026-05-03 — ADR-0009 (status widget worker moved to website repo); CI + Dependabot landed; bootstrap session memory captured*
*v1.1 — May 2026 — added policy docs (RUNBOOK, PLUGIN-GOVERNANCE, CHILD-SAFETY-PRIVACY) and ADRs 0005-0008*
*v1.0 — initial creation*
