# Changelog

All notable changes to the MeteoricCraft infrastructure are documented here.

Format inspired by [Keep a Changelog](https://keepachangelog.com/).

---

## [1.3.0] — 2026-05-08

> Five-day arc that took MeteoricCraft from a barebones 13-plugin survival
> server to a 31-plugin economy/RPG/PvP world with custom bosses, land-claim
> protection, 3D web map, branded spawn build, separate duels arena, hidden
> cave, and nightly automated backups.

### Added — public economy-server format (ADR-0010)

After Merric's first test-join ("too boring and bland — needs to be bad ass"),
the server posture flipped from whitelist-only to public economy survival
with PvP. Compensating controls: CoreProtect rollback, anti-combat-log
enforcement, spawn safe-zone, active moderation, Discord adult monitoring
(when configured). Full rationale + threat model in
[ADR-0010](docs/decisions/ADR-0010-public-economy-server-format.md).

### Added — 18 new plugins

Round-by-round, all 1.21.11-verified:

**Round 3 — economy gameplay foundation:**
- `crazycrates` v5.0.0 — 3 crate tiers (Common / Rare / Legendary) with
  custom loot tables (`config/crates/*.yml`)
- `quickshop-hikari` v6.2.0.11 — admin-and-player chest shops
- `ndailyrewards` v3.4.0 — 7-day cycling login bonus, economy-themed
  (Day 1 = $50+bread; Day 7 = $1500+Legendary Key)
- `anti_combatlog` v1.1 — punishes combat logout
- `tab-was-taken` v6.0.2 — branded tablist + scoreboard

**Round 4 — RPG + ops + visuals:**
- `auraskills` v2.3.12 — 11 skills auto-track on play (mining, fighting,
  archery, fishing, foraging, etc.) with passive bonuses, abilities,
  level-up XP bar
- `decentholograms` v2.9.10 — 5 floating text labels at spawn ("☄
  MeteoricCraft ☄", "💰 SHOP", "🎁 CRATES", "🌍 WILDERNESS", "📅 DAILY
  REWARDS")
- `mythicmobs` v5.12.0 — 3 custom bosses with abilities + crate-key
  drops:
  - **Cosmic Knight** (1500 HP, skeleton-base, drops Common Key) —
    spawns at night surface y>100, 3% replace
  - **Magma Sentinel** (5000 HP, blaze-base, fire-immune, drops Rare
    Key) — spawns in nether biomes, 10% replace
  - **Void Reaver** (12000 HP, wither_skeleton-base, lifesteal +
    teleport + summons adds, drops Legendary Key + netherite + 50%
    enchanted item) — admin-summoned event mob only
- `griefprevention` v16.18.7 — chunk-claim land protection (golden
  shovel tool; 100 starter blocks + 100/hr accrual cap 5000)
- `bluemap` v5.16-spigot — 3D web map at port 8100 (cosmic dark sky,
  no live player markers per CHILD-SAFETY-PRIVACY §2.2)
- `placeholderapi` v2.12.2 — required by TAB and other plugins for
  variable expansion in messages
- `duels` (latest) — 1v1 PvP duels with arena `stone-brick-1` and
  `balanced` kit (sharpness-2 iron + iron armor + golden apple +
  cooked beef)
- `auctionhouseplus` v3.5 — server-wide item auction marketplace
- `villagershop` v1.1.2 — interactive admin tool for villager-NPC
  shops (we ended up using QuickShop for our spawn shops; VillagerShop
  remains available for player-driven NPC trades)

**Round 5 — voting + RTP + commands:**
- `votespeed` v1.0.1 — all-in-one voting plugin (NuVotifier + rewards
  + VoteParty + Bedrock-Form support)
- `simplertp` v1.3.0 — proper `/rtp` command (EssentialsX 2.21.2 has
  none; `EssentialsX-2.21.2.jar` core only registers /home /sethome
  /tpa /msg /balance, and `EssentialsXSpawn-2.21.2.jar` registers
  only /spawn /setspawn — neither has random teleport)
- `EssentialsXSpawn-2.21.2.jar` — added to PLUGINS direct-URL list to
  register /spawn /setspawn (was missing earlier)

### Added — gameplay configs

All in `config/` directory in the repo (drop-in copies of what's live on
the host):

- `config/crates/Common.yml` `Rare.yml` `Legendary.yml` — full loot tables,
  particle effects, sounds, hologram captions
- `config/NDailyRewards-days.yml` — 7-day economy cycle (ASCII-only after
  em-dash unicode broke the YAML parser)
- `config/essentials-kits-fragment.yml` — `starter` kit (24h cooldown:
  cooked beef + stone tools + planks + torches) + `merric` kit (one-time:
  iron tools + ender chest, owner-only via `essentials.kits.merric` perm)
- `config/essentials-welcome-book.txt` — 5-page written book given on
  first `/kit welcome` claim (cosmic story, command cheatsheet, rules,
  credits to Merric + Shane)
- `config/duels-arenas.yml` `duels-kits.yml` — single arena at (100,70,100)
  + balanced kit
- `config/villagershop-shops.yml` — 3 admin merchants config (kept as
  reference; VillagerShop's actual schema was incompatible with config-
  driven setup, pivoted to QuickShop chest shops at spawn instead)
- `config/holograms/spawn-*.yml` — 5 DecentHolograms at spawn cardinal
  edges + center beacon
- `config/mythicmobs/Mobs-CustomBosses.yml`, `Skills-MeteoricSkills.yml`,
  `DropTables-MeteoricDrops.yml`, `RandomSpawns-CustomRandomSpawns.yml`
  — full boss + ability + drop + spawn-rule definitions
- `config/bluemap/core.conf` `webserver.conf` `maps-world.conf` — render
  config (1 thread for co-tenant politeness; 0.0.0.0:8100; cosmic sky)
- `config/griefprevention-config.yml` — overworld-only claims, 100
  starter blocks, 25-block min size (anti-cheese), PvP-allowed-in-
  wilderness rules

### Added — programmatic builds

NOT in git (they live in world data) but documented for replay:

- **Spawn build** at (0, 70, 0): 41×41 platform (polished_andesite +
  diorite cross), 4 hollow stone-brick corner towers (12 blocks tall,
  end_rod tops, lanterns inside), 4 deepslate corner pads, polished
  blackstone perimeter wall, central 22-block-tall meteor pillar
  (deepslate → nether bricks → magma + glowstone shell → diamond pad
  + working Speed beacon with 3-tier iron pyramid), 4 floating magma
  debris clusters, sea_lantern walkways, diamond/gold/emerald crate
  pedestals (south edge) and shop pedestals (north edge), trophy
  backdrop walls, RTP pressure-plate portal at east edge with hidden
  command block (vanilla `spreadplayers 0 0 100 5000 false @p`).
- **Duels arena** at (100, 70, 100): 21×21 grass + 4-block stone-brick
  walls + 5×5 glass spectator deck above + iron pyramid + beacon. Two
  gold-block spawn pads at +/-5 X facing each other.
- **Secret Cave** at (220, 25, 220): hidden 21×21×10 chamber, deepslate-
  bricks/cobbled-deepslate walls, 5 ceiling sea_lanterns, obsidian
  podium with enchanting_table + max-level bookshelf walls, 2 treasure
  chests, diamond pad + beacon (NW corner exit landmark), 4 soul
  campfires for blue ambient. Entry mechanism reserved for Merric to
  design.

### Added — backups (Phase 6)

- Restic v0.18.1 installed at `~/bin/restic` (no-sudo binary install
  from GitHub releases)
- Repository at `/home/shane/minecraft-restic` (initial location;
  migrate to `/mnt/<backup-volume>/minecraft-restic` later with one
  sudo command)
- Password file at `~/.restic-password` (chmod 600, generated via
  `openssl rand -base64 24`)
- First snapshot `ec6dd8a2` — 235 files, 95 MiB → 42 MiB stored
- Daily backup cron at 3am: `0 3 * * * cd ~/merric-minecraft && PATH=~/bin:... ./scripts/backup.sh`
- Backup logs at `logs/backup.log`

### Added — supporting infra

- `EssentialsXSpawn` module added explicitly (we'd installed only the
  core JAR previously; /spawn was missing)
- `ENABLE_COMMAND_BLOCK: "true"` in compose env (persists across container
  recreates; sed-edits to server.properties got wiped on every boot)
- `MAX_TICK_TIME: "120000"` — Paper watchdog tolerance from default 60s
  → 120s, after BlueMap initial render at 2 threads starved the main
  game-tick thread and Paper killed the server (CPU 280%, watchdog
  fired). BlueMap also reduced from 2 → 1 render thread.
- LuckPerms groups: `default` (24 perms — sethome×3, /home, /tpa, /msg,
  /spawn, /rtp, /balance, /pay, basic shop/crate/daily/kit perms,
  anti-combatlog player) and `admin` (inherits default + full
  coreprotect/worldedit/worldguard/quickshop/crazycrates/essentials/
  luckperms admin). NO chat prefixes per Merric's "subtle perks only"
  rule. Members: `.Metric1720`, `StratoSurf`.
- WorldGuard `spawn` region defined (-25..25, 60..110, -25..25) with
  9 deny flags + priority 10 + 2 owners.
- Bukkit `commands.yml` aliasing `/rtp` `/randomtp` `/wild` to vanilla
  `/spreadplayers` (kept as fallback even though SimpleRTP is the
  primary registrar now).

### Changed

- itzg/minecraft-server image bumped from `:java21` → `:java25` (WorldEdit
  7.4.x ships Java 25 bytecode).
- playit-agent bumped 0.16 → 0.17 (matches what playit's setup wizard
  distributes).
- Wrangler dependency bumped 3.114.17 → 4.87.0 (auto-merged Dependabot PR
  #1; Cloudflare Worker runtime — does not affect this repo since
  ADR-0009 moved the worker to the website repo, but the dependency
  followed).
- `MOTD` rebranded with cosmic theme: `§6§l☄ §c§lMeteoricCraft §6§l☄
  §r§8» §fEconomy Survival §8• §ePvP §8• §bCross-Play §8• §amc.merricstrough.com`
- `TAB` plugin tablist customized with branded header/footer (player
  count, TPS, connect address).

### Lessons logged

- **EssentialsX is modular** — `EssentialsX-2.21.2.jar` core does NOT
  ship `/rtp`, `/randomteleport`, `/wild`, or any random-teleport
  command. EssentialsXSpawn registers ONLY `/spawn` and `/setspawn`.
  For random teleport, install a dedicated plugin (we use SimpleRTP).
- **Paper rcon is async-safe-checked** — entity `/summon`, complex
  block-entity NBT (signs with formatted text, banners), and some
  `/fill` operations get rejected with "Asynchronous Cannot perform
  command async!" Use `/execute as <player>` for player-context
  commands; defer entity summons to in-game admin.
- **Vanilla `/execute as @p run <plugin-command>` does NOT work** —
  `execute ... run` only invokes vanilla commands. Bukkit aliases
  registered via `commands.yml` are also not callable from /execute.
  Plugin commands must come from chat or directly from rcon.
- **YAML comment lines (`#`) inside `|` block scalars are content,
  not comments** — itzg's plugin downloader parsed `#` comment lines
  as plugin slugs. Comments must live OUTSIDE the block scalar.
- **NDailyRewards has docs/code drift** — the plugin's own header
  comment lists `[title]` and `[subtitle]` action prefixes; the actual
  3.4.0 parser rejects them with "For input string: type". ASCII-only
  + omit those prefixes.
- **MOTD with `\n` in `.env` breaks docker compose env parsing** if
  sed expands the backslash. Single-line MOTDs are safer.
- **HuggingFace ZeroGPU has a quota** — without an `HF_TOKEN`, image
  generation is rate-limited to ~0 seconds per session for anonymous
  use. Server icon generation deferred until Shane sets HF_TOKEN.

### Deferred / queued for next session

- Server icon (HF token blocker; or Shane provides 64×64 PNG)
- DiscordSRV bot setup (Shane creates Discord + bot token)
- VoteSpeed config — register MeteoricCraft on minecraft-server-list /
  planetminecraft / topg, paste their callback URLs into VoteSpeed
- Migrate restic backups from `~/minecraft-restic` to `/mnt/<backup-volume>/minecraft-restic` (one sudo cmd)
- Secret Cave entry puzzle (Merric design pass)
- Trophy item frames + cardinal banners at spawn (rcon async issue;
  needs in-game player executor)

---

## [1.2.0] — 2026-05-03

### Removed — Cloudflare Worker (moved to website repo)

The standalone status worker (`worker/`) and its Cloudflare resources have
been removed. The website repo (`MeteoricMetric/MeteoricMetric.github.io`)
already has a multi-endpoint worker (`merricstrough-now-playing`) with a
`/api/minecraft-status` route that does the same job — discovered during
2026-05-02 bootstrap. Two implementations of the same widget is worse than
one.

- Removed `worker/` directory (frontend-snippet.astro, src/index.js, wrangler.toml, package.json, package-lock.json)
- Removed `worker-smoke` CI job
- Removed `npm` ecosystem block from `.github/dependabot.yml`
- Removed `worker/*` lines from `.gitignore`
- Deleted Cloudflare worker `merric-mc-status` and KV namespace `MC_STATUS_CACHE`

See [`docs/decisions/ADR-0009`](docs/decisions/ADR-0009-status-widget-worker-location.md)
for full rationale and consequences.

### Added

- **ADR-0009** — Status widget worker lives in the website repo, not here
- **`.github/workflows/ci.yml`** — light validation workflow (shellcheck, compose validate)
- **`.github/dependabot.yml`** — weekly grouped patches (docker + github-actions ecosystems)
- **`.gitattributes`** — LF normalization for shell scripts (run on Ubuntu host)
- **`LICENSE`** — MIT (referenced by README but not previously present)
- **`CLAUDE.local.md`** (gitignored) — operational specifics per master §15 redaction discipline
- **12 mattpocock skills** at `.agents/skills/` for Claude Code / other AI assistants

### Changed

- **`MINECRAFT-BUILD-GUIDE.md`** — Phase 6 ("Status widget") replaced with cross-reference to website repo
- **`docs/CHILD-SAFETY-PRIVACY.md`** — `players.sample` worker references point to website repo
- **`docs/decisions/ADR-0004`** — "Status widget" section noted as superseded by ADR-0009
- **`CLAUDE.md`** — removed `worker/frontend-snippet.astro` cross-reference; added ADR-0009 to ADR list
- **`README.md`** — Cloudflare Worker stack-list item rewritten as link to website repo's worker

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
