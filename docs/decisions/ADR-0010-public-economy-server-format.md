# ADR-0010: Switch from whitelist-only to public economy survival format

## Status

Accepted — 2026-05-07 — Supersedes the "ENFORCE_WHITELIST=true is non-negotiable in production" stance from
the original [`CLAUDE.md`](../../CLAUDE.md) §security and amends [ADR-0008](ADR-0008-child-safety-privacy-boundaries.md)
to reflect the new gameplay format and its compensating controls.

## Context

The server bootstrapped 2026-05-03 was framed as a whitelist-only friends-and-family server. After the
core infrastructure was up (cross-play, playit tunnel, status widget, plugins, rcon admin), Merric (project
owner, age 13) clarified his actual product vision after a brief test-join:

> "It's too boring and bland and just a normal server. I want it to be really bad ass."

His specified plugin list — **EconomyShopGUI, BetterRTP, CombatLogX, CrazyCrates, DailyRewards, PVP=on,
spawn protection 5 blocks** — describes a well-known server format: **public economy survival with PvP**.
The whitelist requirement is incompatible with the genre's social model (friend-of-friend joins, discoverability
through vote sites, quick onboarding). Forcing the whitelist would either suppress organic growth or push
all friction onto Merric (who would have to manually approve every connection).

The original whitelist policy was written with a more conservative "trusted-people-only" use case in mind.
Merric's actual use case warrants a different security posture — one that lowers the joining barrier while
strengthening compensating controls against the actual threats (griefing, harassment, predator contact).

## Decision

**Disable `ENFORCE_WHITELIST` in `docker-compose.yml`** (set to `false`). Server becomes joinable by anyone
who has the connection address.

**To balance the increased exposure, the following mitigations become mandatory** (not optional):

1. **CoreProtect** must be installed and running. Without it, griefing is unrecoverable and the format is unsafe.
   Manual JAR install path is documented inline in `docker-compose.yml` until Modrinth/Hangar tag a 1.21.11 build.
2. **WorldGuard spawn protection** at minimum 5 blocks from spawn point. Players cannot break/place/PvP at spawn.
   Configured via WorldGuard regions; verified at boot.
3. **Active moderation channel.** Merric and Shane are both ops. Shane has eyes on chat behaviour as the
   accountable adult per CLAUDE.md §0.
4. **Anti-combat-log enforcement** (`anticombatlog` plugin) — players cannot disconnect to escape combat.
5. **DiscordSRV with adult-monitored channel** — required before this server is publicly advertised on
   server-list sites. Server-event-only mode keeps personal chat off Discord but lets Shane spot incidents.
6. **No public advertising / discoverability** until #5 is done. Until then, joins are friends + their friends only.

The safety architecture in [ADR-0008](ADR-0008-child-safety-privacy-boundaries.md) and
[`docs/CHILD-SAFETY-PRIVACY.md`](../CHILD-SAFETY-PRIVACY.md) is preserved — this ADR shifts the *primary*
control from "whitelist gate at the door" to "compensating controls inside the door". Privacy rules
(no full surnames in chat, no real-time location, no full birthdays etc.) remain identical.

## Alternatives considered

- **Keep the whitelist + make adding friction-free** — the in-game `/whitelist add <name>` command takes a
  few seconds. Considered, but doesn't solve the "friend of friend" case (Merric's friend can't add their
  own friend without going through Merric/Shane), which is the exact dynamic that grows a kid server.
- **Application form on the website** (low-friction self-service) — would work but adds engineering surface
  area (form, webhook, review queue, anti-spam) for a problem CoreProtect + active moderation already
  solves more cheaply.
- **Whitelist for a launch period, then disable once CoreProtect lands and proves itself** — staged. Considered
  but creates a "bait and switch" experience where early friends get one onboarding flow and later friends
  get another. Cleaner to commit to one posture and document the safety net.

## Consequences

**Compose changes:**
- `ENFORCE_WHITELIST: "true"` → `"false"`
- New gameplay plugins added to `MODRINTH_PROJECTS`: crazycrates, quickshop-hikari, ndailyrewards,
  anti_combatlog, tab-was-taken
- CoreProtect documented as a manual install (no working programmatic source for 1.21.11 yet)
- spark dropped from `PLUGINS` (Paper bundles it natively as of 1.21.11)
- BetterRTP from Merric's list folded into EssentialsX's built-in `/rtp`

**Doc changes:**
- `CLAUDE.md` §security — "ENFORCE_WHITELIST=true is non-negotiable" line softened to "ENFORCE_WHITELIST may
  be `false` IFF the ADR-0010 mitigations are in place"
- `docs/CHILD-SAFETY-PRIVACY.md` — moderation section gains the "compensating controls" framing
- `docs/RUNBOOK.md` — adds a moderation incident playbook (kick/ban/rollback steps)

**Operational consequences:**
- Server is joinable by anyone with the connection address — no longer "discreet by default"
- Griefing risk goes from "blocked" to "rolled-back-when-discovered". CoreProtect rollback is the firefighting
  mechanism. Quarterly grief-rollback drill cadence (parallel to ADR-0006's restore drill).
- Chat moderation expectation rises — Shane needs to occasionally read chat (or set up DiscordSRV bridge with
  notification on join + first-chat events).
- If a problem player is banned, their CoreProtect-logged actions can be rolled back with one command:
  `/co rollback u:player t:7d r:200`.

**What we are NOT changing:**
- 2FA on all platform accounts (CLAUDE.md §5.2)
- No PII / surnames in chat (CHILD-SAFETY-PRIVACY §3)
- RCON localhost-only (CLAUDE.md §security)
- Backups via restic (ADR-0006) — still mandatory
- Cross-play architecture (ADR-0004)

## Trigger to revisit

- Any incident worse than minor grief (a real harassment / predator-contact attempt, even handled successfully).
  Re-evaluate whether public posture is still appropriate.
- If CoreProtect ever lapses (plugin breaks, doesn't get updated). Re-enable whitelist as the fallback gate
  while the rollback layer is being rebuilt.
- Annual review (with the rest of `CHILD-SAFETY-PRIVACY.md` annual review).

---

*Author: Shane (parent / accountable adult), Merric (owner) advised, Claude Code drafting. 2026-05-07.*
