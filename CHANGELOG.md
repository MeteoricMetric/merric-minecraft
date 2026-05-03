# Changelog

All notable changes to the MeteoricCraft infrastructure are documented here.

Format inspired by [Keep a Changelog](https://keepachangelog.com/).

---

## [1.1.0] — 2026-05-02

### Added — new policy documents

- **`docs/CHILD-SAFETY-PRIVACY.md`** — foundational policy doc covering:
  - Public/private data taxonomy (what's acceptable on the website, what stays private)
  - Identity boundaries (hostname, handles, real-name handling)
  - Discord integration posture (event-notify-only by default)
  - Moderation policy with 4-tier escalation ladder
  - Parent override authority
  - Quarterly review cadence
- **`docs/PLUGIN-GOVERNANCE.md`** — treats plugins as production dependencies:
  - Approved sources (Modrinth, Hangar, BukkitDev, official GitHub only)
  - Pinning policy by plugin tier
  - Full v1.1 plugin manifest
  - Install / update / remove processes
  - Permission model and quarterly audit
- **`docs/RUNBOOK.md`** — operational reference:
  - Change-management ladder (🟢 safe alone / 🟡 with Dad / 🔴 adult-only)
  - Common incidents and triage
  - Restore drill cadence and procedure
  - Pre-change checklists
  - Post-incident review template
  - Weekly habit checklist

### Added — new ADRs

- **ADR-0005** — Network exposure strategy (playit now, VPS+WireGuard later, never Cloudflare Tunnel for game traffic)
- **ADR-0006** — Backup and restore strategy (3-2-1, restic, quarterly drills)
- **ADR-0007** — Plugin governance (decision to apply production-dependency rigor to plugins)
- **ADR-0008** — Child-safety and privacy boundaries (decision to formalize policy)

### Changed

- **`docker-compose.yml`** — replaced `USE_AIKAR_FLAGS` with `USE_MEOWICE_FLAGS`. Aikar's flags were tuned for Java 8/11; MeoWiCE is the modern Java 21+ choice via the itzg image.
- **`docker-compose.yml`** — plugin section now categorizes by tier, references PLUGIN-GOVERNANCE.md, explains pinning rationale inline.
- **`MINECRAFT-BUILD-GUIDE.md`** — substantial revision:
  - Header now references companion docs and all sibling ADRs
  - "What we're building" — explicit console caveat (Xbox/PS/Switch require BedrockConnect workaround, not zero-friction)
  - DiscordSRV section — restructured around event-notify-only default with documented upgrade path
  - BlueMap section — reframed as CPU-bound (not GPU-accelerated; the 5090's GPU isn't doing anything for BlueMap)
  - Added Phase 5.7 — console (Xbox/PS/Switch) onboarding via BedrockConnect
  - Phase 7 (BlueMap public) — added privacy precondition (no live player markers)
  - Phase 8.5 (restore practice) — promoted to recurring quarterly drill cadence
  - Phase 9 — references RUNBOOK.md change-management ladder
  - Phase 10 — updated to reference all 5 ADRs (0004-0008)
  - Future enhancements list — added VPS migration, B2 off-site backups, project-identity domain, AI LoreBot
- **`worker/frontend-snippet.astro`** — major changes for v1.1:
  - Default privacy: count of online players shown without names (per CHILD-SAFETY-PRIVACY.md §2.4). Previous version showed names if available.
  - Added "Console support" details/summary section explaining BedrockConnect workflow
  - Bedrock label clarified as "Mobile / Win10" to align with the console caveat
- **`.env.example`** — added v1.1 sections:
  - DiscordSRV configuration with `DISCORD_CHAT_BRIDGE_ENABLED=false` default
  - Memory section gained co-tenancy guidance for the workstation
  - Header references RUNBOOK and CHILD-SAFETY-PRIVACY
- **`README.md`** — full revision: doc table, console caveat in connection section, v1.1 stack list, expanded references
- **`CLAUDE.md`** — change-management ladder aligned with RUNBOOK §1; cross-references updated for all new docs
- **`docs/decisions/ADR-0004`** — header note about v1.1 sibling ADRs; modernized JVM-flag reference; updated references

### Migration notes (from v1.0 to v1.1)

If you were already running v1.0:

1. **Pull the v1.1 docker-compose.yml** — restart the container to pick up `USE_MEOWICE_FLAGS`. Run a backup before this.
2. **Add the new docs** — `docs/RUNBOOK.md`, `docs/PLUGIN-GOVERNANCE.md`, `docs/CHILD-SAFETY-PRIVACY.md`, ADRs 0005-0008.
3. **Verify DiscordSRV configuration** — if you previously enabled chat bridging, decide whether to keep it or roll back to event-notify-only per the new default. Document the decision either way.
4. **Re-deploy the Worker frontend** if you're using the snippet — the privacy default changed from "names if available" to "count only" by default.
5. **Schedule the first restore drill** — pick a date in the next 30 days, run through `RUNBOOK.md` §3.3, record outcome.
6. **Copy the new ADRs to the website repo** — see MINECRAFT-BUILD-GUIDE.md Phase 10.1.

### Acknowledgments

The v1.1 revision was informed by an external research report that highlighted:
- The misconception that Cloudflare Tunnel could carry Minecraft (it can't — needs Spectrum)
- BlueMap's CPU-bound nature (not GPU-accelerated)
- Console Bedrock's BedrockConnect workaround requirement
- The need for explicit privacy taxonomy and plugin governance
- The benefit of distinguishing JVM flag generations (Aikar vs MeoWiCE)
- The value of a quarterly restore drill cadence

These corrections strengthened the project. The research report is referenced in ADR-0005 and ADR-0006.

---

## [1.0.0] — 2026-05-02 (initial release)

### Added

- `docker-compose.yml` — Paper 1.21.11 + plugins + playit.gg agent stack
- `.env.example` — environment template
- `MINECRAFT-BUILD-GUIDE.md` — phase-by-phase build walkthrough
- `scripts/ops.sh` — operational entry point
- `scripts/backup.sh` — atomic restic backup with retention
- `scripts/restore.sh` — interactive restore with confirmation
- `worker/src/index.js` — Cloudflare Worker implementing Minecraft SLP protocol
- `worker/wrangler.toml` — Worker config with KV cache and cron
- `worker/frontend-snippet.astro` — `/minecraft` page component
- `docs/decisions/ADR-0004-minecraft-server-architecture.md` — initial architecture decision
- `README.md`, `CLAUDE.md`, `.gitignore` — repo scaffolding

---

*Maintained by Shane & Merric Strough.*
