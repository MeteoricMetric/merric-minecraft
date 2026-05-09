# merric-minecraft

Infrastructure for **MeteoricCraft**, a Paper 1.21.11 Minecraft server with Bedrock cross-play, hosted by [Merric Strough](https://merricstrough.com).

> Live status & connection details: https://merricstrough.com/minecraft

## What this is

A real, runnable Minecraft server with the engineering rigor of a small production app. Containerized, version-controlled, backup-automated, with a live status widget on the website and a kid-friendly ops layer so Merric can run day-to-day without help.

Built side-by-side by Merric (13) and his dad — this is the infrastructure-as-code half of the [merricstrough.com](https://merricstrough.com) project family.

## Stack (v1.3)

- **Paper 1.21.11** Minecraft server (`itzg/minecraft-server:java25` image, modern JVM flags)
- **Geyser + Floodgate** for Bedrock cross-play (mobile + Win10/11 native; consoles via documented BedrockConnect workaround)
- **playit.gg** tunnel for public connectivity (no port forwarding, home IP hidden)
- **31-plugin economy-survival stack** (see `docs/PLUGIN-GOVERNANCE.md` §3 for the full manifest): infrastructure (EssentialsX + Spawn module, LuckPerms, CoreProtect, WorldEdit, WorldGuard, Multiverse, Vault, PlaceholderAPI, ViaVersion/Backwards), economy (CrazyCrates, QuickShop-Hikari, NDailyRewards, AuctionHouse, VoteSpeed), gameplay (AuraSkills, MythicMobs, Duels, SimpleRTP, anti-combat-log, GriefPrevention), polish (TAB, DecentHolograms, BlueMap, squaremap, Chunky, DiscordSRV)
- **Docker Compose** for orchestration
- **restic** for daily atomic world backups (7-day rolling, quarterly restore drills)
- **Public economy server** per [ADR-0010](docs/decisions/ADR-0010-public-economy-server-format.md) — whitelist replaced by compensating controls (CoreProtect rollback, anti-combat-log, GriefPrevention claims, spawn safe-zone, dual-admin moderation)
- **Live status widget** at [merricstrough.com/minecraft](https://merricstrough.com/minecraft) (privacy-filtered: count without names by default) — implemented in the [website repo's worker](https://github.com/MeteoricMetric/MeteoricMetric.github.io/tree/main/worker), per [ADR-0009](docs/decisions/ADR-0009-status-widget-worker-location.md)

## Quick start

```bash
git clone https://github.com/MeteoricMetric/merric-minecraft.git
cd merric-minecraft
cp .env.example .env
# edit .env with your values
./scripts/ops.sh start
```

Full walkthrough: see `MINECRAFT-BUILD-GUIDE.md`.

## Day-to-day operations

```bash
./scripts/ops.sh start              # bring everything up
./scripts/ops.sh stop               # take it down cleanly
./scripts/ops.sh status             # is it running?
./scripts/ops.sh logs               # tail the server log
./scripts/ops.sh online             # who's playing right now
./scripts/ops.sh whitelist <name>   # add a friend
./scripts/ops.sh backup             # manual backup
./scripts/ops.sh help               # full command list
```

Operational change-management ladder (🟢 safe alone / 🟡 with Dad / 🔴 adult-only): see `docs/RUNBOOK.md` §1.

## Documentation

| Doc | Purpose |
|---|---|
| [`MINECRAFT-BUILD-GUIDE.md`](MINECRAFT-BUILD-GUIDE.md) | Phase-by-phase initial build walkthrough |
| [`docs/RUNBOOK.md`](docs/RUNBOOK.md) | Day-to-day ops, change-management ladder, common incidents, restore drills |
| [`docs/PLUGIN-GOVERNANCE.md`](docs/PLUGIN-GOVERNANCE.md) | Plugin manifest, approved sources, install/update/remove processes |
| [`docs/CHILD-SAFETY-PRIVACY.md`](docs/CHILD-SAFETY-PRIVACY.md) | Public/private data taxonomy, identity boundaries, moderation policy |
| [`docs/decisions/ADR-0004`](docs/decisions/ADR-0004-minecraft-server-architecture.md) | Overall stack architecture |
| [`docs/decisions/ADR-0005`](docs/decisions/ADR-0005-network-exposure-strategy.md) | Network exposure strategy (playit now, VPS later, why not Cloudflare Tunnel) |
| [`docs/decisions/ADR-0006`](docs/decisions/ADR-0006-backup-restore-strategy.md) | Backup and restore strategy (3-2-1, restic, drills) |
| [`docs/decisions/ADR-0007`](docs/decisions/ADR-0007-plugin-governance.md) | Plugin governance decision |
| [`docs/decisions/ADR-0008`](docs/decisions/ADR-0008-child-safety-privacy-boundaries.md) | Child-safety and privacy decision |
| [`docs/decisions/ADR-0009`](docs/decisions/ADR-0009-status-widget-worker-location.md) | Status widget worker lives in the website repo, not here |
| [`docs/decisions/ADR-0010`](docs/decisions/ADR-0010-public-economy-server-format.md) | Public economy-server format (replaces whitelist with compensating controls) |
| [`docs/MERRIC-OPS-MANUAL.md`](docs/MERRIC-OPS-MANUAL.md) | Day-to-day ops guide for Merric (admin commands, boss spawning, crate keys, when to ask Shane) |
| [`docs/PLAYER-GUIDE.md`](docs/PLAYER-GUIDE.md) | Public-facing player guide (how to connect, what to do, rules, parents' note) |

## Connection

```
Java Edition:    mc.merricstrough.com
Bedrock (mobile/Win10): <playit-bedrock-hostname>:<port>
Console (Xbox/PS/Switch): via BedrockConnect — see /minecraft on the website
Live web map:    https://map.merricstrough.com  (player markers OFF by policy)
```

**Public access.** No whitelist — see [ADR-0010](docs/decisions/ADR-0010-public-economy-server-format.md) for the security model that replaces it.

## License

MIT — see `LICENSE`.

---

*Built by Merric & Shane Strough · MeteoricMetric · 2026*  
*v1.3 — May 2026 (public economy format, 31-plugin runtime, ops manual + player guide)*
