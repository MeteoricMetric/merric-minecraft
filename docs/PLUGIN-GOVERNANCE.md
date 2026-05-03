# Plugin Governance Policy

> Plugins on a Minecraft server are production dependencies. They run inside the same JVM as the game, have full access to the world data, and can read/write everything the server can. A bad plugin can grief, leak data, or take the server down. A compromised plugin can do worse. This policy treats plugins with the rigor that risk demands.

**Owner:** Shane Strough  
**Operator:** Merric Strough  
**Companion ADR:** [ADR-0007](decisions/ADR-0007-plugin-governance.md)

---

## 1. Approved sources

A plugin may be installed if and only if it comes from one of these sources:

| Tier | Source | Trust level | Notes |
|---|---|---|---|
| 1 | **Modrinth** | High | Verified publishers, clean metadata, automatic updates via `MODRINTH_PROJECTS` env var |
| 1 | **PaperMC Hangar** | High | Curated, paper-team-adjacent, modern UX |
| 2 | **SpigotMC / BukkitDev** | Medium | Long-tail; widely used but variable quality. OK for established plugins (EssentialsX, Multiverse, BlueMap) |
| 2 | **Official GitHub release page of a known project** | Medium-High | OK if the project is on Modrinth/Hangar but you need a specific build; pin the release tag |
| 3 | **Direct URL from a trusted CDN** | Medium | OK only for `https://download.geysermc.org/...` and similar first-party project distribution |
| ❌ | Random forum threads | NO | Never |
| ❌ | "I found a fork that has X" | NO | Submit a PR to the upstream instead |
| ❌ | Discord server jar dumps | NO | Never |
| ❌ | Anything where the only documentation is "join our Discord" | NO | Mature plugins document on a real site |

**Single rule:** if you can't link to a public, dated, source-of-truth release page, don't install it.

---

## 2. Pinning policy

### 2.1 Version-critical plugins (always pinned)

These plugins handle authentication, network ingress, or cross-version protocol. Pin them to specific versions:

- **Geyser-Spigot** — current minor version line
- **Floodgate** — current minor version line
- **ViaVersion / ViaBackwards** — current minor version line

For these, monitor the project's release notes / Discord. Do not auto-update on a schedule. Read the changelog first.

### 2.2 Stable plugins (latest-of-major is acceptable)

These plugins are mature, conservative, and rarely break:

- **EssentialsX** — track latest in the 2.x line
- **LuckPerms** — track latest in the 5.x line
- **CoreProtect** — track latest in the 22.x line
- **WorldEdit / WorldGuard** — track latest in the 7.x line
- **Vault** — track latest

For these, the `MODRINTH_PROJECTS` and `SPIGET_RESOURCES` env vars in `docker-compose.yml` resolve to the latest matching the Minecraft version. Acceptable risk for the maturity of these projects.

### 2.3 Optional / utility plugins

- **BlueMap** — pin to a known-working version; update deliberately
- **Spark** — track latest; very stable
- **Chunky** — track latest
- **DiscordSRV** — pin; configuration-sensitive

### 2.4 Never used

- "Anti-cheat" plugins promising magic detection (NoCheatPlus, Matrix, etc.) — high false-positive rates, often more harmful than helpful for a friend server with whitelist
- Plugins shipped via cracked-server communities
- Plugins without a public source repository
- Plugins claiming to "boost FPS" or "reduce lag" with no benchmark methodology

---

## 3. The plugin manifest

The authoritative list of plugins for MeteoricCraft v1.1:

### 3.1 Tier 1 — Required (cross-platform & authentication)

| Plugin | Source | Pin policy | Purpose |
|---|---|---|---|
| Geyser-Spigot | `download.geysermc.org` direct URL | Specific version | Bedrock protocol bridge |
| Floodgate | `download.geysermc.org` direct URL | Specific version | Bedrock account auth (lets Bedrock players join without Java accounts) |
| ViaVersion | Modrinth `viaversion` | Latest 5.x | Cross-Java-version client compat |
| ViaBackwards | Modrinth `viabackwards` | Latest 5.x | Backward Java client compat |

### 3.2 Tier 2 — Required (admin & permissions infrastructure)

| Plugin | Source | Pin policy | Purpose |
|---|---|---|---|
| LuckPerms | Modrinth `luckperms` | Latest 5.x | Permission system; required by EssentialsX and most other plugins |
| EssentialsX | SpigotMC resource 9089 | Latest 2.x | Homes, warps, /tpa, kits, /spawn, /msg, basic moderation tools |
| CoreProtect | Modrinth `coreprotect` | Latest 22.x | Block logging + grief rollback; fundamental anti-grief insurance |
| WorldEdit | Modrinth `worldedit` | Latest 7.x | Admin building tools; required by WorldGuard |
| WorldGuard | Modrinth `worldguard` | Latest 7.x | Region protection (spawn protection, claim regions) |
| Vault | SpigotMC resource 34315 | Latest | Permission/economy API bridge — many plugins require it |

### 3.3 Tier 3 — Recommended (quality of life)

| Plugin | Source | Pin policy | Purpose |
|---|---|---|---|
| Multiverse-Core | SpigotMC resource 390 | Latest 4.x | Multi-world support (creative test world later) |
| Chunky | Modrinth `chunky` | Latest | Async chunk pre-generation; eliminates new-area lag |
| Spark | Modrinth `spark` | Latest | Performance profiler for diagnosing TPS issues |

### 3.4 Tier 4 — Optional (configuration-sensitive)

| Plugin | Source | Pin policy | Purpose | Default mode |
|---|---|---|---|---|
| DiscordSRV | SpigotMC resource 18494 | Pin specific version | Discord integration | **Server-event notifications only** (NOT chat bridge) per CHILD-SAFETY-PRIVACY.md §4 |
| BlueMap | Hangar BlueMap | Pin specific version | Live web map | Phase 2 — not enabled until Phase 0 server is stable for 2+ weeks |

### 3.5 Tier 5 — Watchlist (might be added later, deliberately)

These are NOT in v1.1 but may be added with a deliberate decision:

- **Simple Voice Chat** (Modrinth `voicechat`) — proximity voice. Privacy-sensitive, would update CHILD-SAFETY-PRIVACY.md before adding.
- **squaremap** (alternative to BlueMap) — leaner web map; might swap if BlueMap proves heavy.
- **GriefPrevention** — claim-based protection. Probably overkill for whitelist-only friend group.

---

## 4. Installing a new plugin

### 4.1 Process

1. **Identify the need** — what gameplay problem does this solve? Who's asking?
2. **Find an approved-source candidate** — only Modrinth, Hangar, BukkitDev, official GitHub
3. **Read the plugin's docs end-to-end** — what does it do, what does it need, what permissions does it grant
4. **Read recent issues / changelogs** — any active bugs, recent breaking changes?
5. **Backup** — `./scripts/ops.sh backup` before any change
6. **Add to `docker-compose.yml`** under the appropriate variable (`MODRINTH_PROJECTS`, `SPIGET_RESOURCES`, or `PLUGINS`)
7. **Update this manifest (§3 above)** with the new plugin's row
8. **Restart the server** — `./scripts/ops.sh restart`
9. **Verify load in logs** — `./scripts/ops.sh logs` and confirm the plugin loaded without errors
10. **Functional test** — verify the plugin does what it should
11. **Configure** — copy any default config, customize, restart
12. **Commit** — `git add docker-compose.yml docs/PLUGIN-GOVERNANCE.md` with a clear commit message
13. **Document** — if it's a Tier 4+ plugin, add a config note to the build guide or runbook

### 4.2 What if the plugin breaks something

Roll back immediately:

1. `./scripts/ops.sh stop`
2. Edit `docker-compose.yml` — remove the plugin URL/ID from the env vars
3. Delete the plugin's jar from `data/plugins/`
4. (If the plugin migrated world data) restore from the pre-install backup
5. `./scripts/ops.sh start`
6. Document the failure in `docs/INCIDENTS.md` (create if doesn't exist) — what plugin, what version, what happened, why we won't try again or what conditions would let us retry

---

## 5. Updating plugins

### 5.1 Update cadence

| Tier | Cadence | Trigger |
|---|---|---|
| 1 (auth/network) | As needed | Security advisory, Mojang version change, broken cross-play |
| 2 (admin) | Monthly review | Check for major releases, read changelogs |
| 3 (QoL) | Quarterly review | Bundled with the website's quarterly identity health check |
| 4 (optional) | Per-plugin | DiscordSRV: read every changelog before updating |

### 5.2 Update process

For any non-trivial update:

1. `./scripts/ops.sh backup` — full backup before update
2. Read the changelog / release notes
3. Check for breaking changes — config migrations, permission changes, dependency bumps
4. Schedule update during a low-activity time
5. `./scripts/ops.sh update` (pulls latest container image) OR edit `docker-compose.yml` with new pinned versions
6. `./scripts/ops.sh restart`
7. Watch logs for 5 minutes — `./scripts/ops.sh logs`
8. Test from a Java client and a Bedrock client
9. Test the specific feature(s) that changed
10. Commit the version bump
11. If anything breaks: roll back per §4.2

### 5.3 Pinned-version updates

When changing the version of a Tier-1 plugin (Geyser, Floodgate, ViaVersion):

- The change is committed to `docker-compose.yml`
- The commit message references the upstream release notes URL
- A line is added to the next entry in `docs/CHANGELOG.md`

---

## 6. Removing a plugin

### 6.1 Removal criteria

A plugin should be removed if:

- It's no longer maintained (no releases in 12+ months)
- It's been replaced by a better alternative
- It's causing performance issues that can't be tuned away
- It's surfaced a security vulnerability
- It's no longer needed (gameplay style changed)
- It conflicts with a higher-priority plugin

### 6.2 Removal process

1. Backup
2. Decide what happens to plugin-managed data
   - Some plugins (LuckPerms, EssentialsX) own data we want to preserve — export first
   - Some plugins (Spark, Chunky) leave no persistent state — safe to just remove
   - Some plugins (CoreProtect) own historical data we may want — keep their database file even after plugin removal, in case we re-enable
3. Remove from `docker-compose.yml`
4. Restart
5. Verify clean startup (no errors about missing plugin)
6. Update §3 of this manifest, marking the plugin as "REMOVED on YYYY-MM-DD — reason"
7. Commit

---

## 7. Plugin permissions and security boundaries

### 7.1 LuckPerms group structure

The standard groups for MeteoricCraft:

| Group | Who | Permissions |
|---|---|---|
| `default` | Every whitelisted player | `essentials.spawn`, `essentials.home`, `essentials.sethome`, `essentials.tpa`, `essentials.msg` |
| `trusted` | Friends after a few weeks of good behavior | `default` + `essentials.warp`, `worldedit.use` (limited) |
| `builder` | Friends working on a specific build with permission | `trusted` + `worldedit.region.*` |
| `admin` | Merric, Shane | `*` (all) |

### 7.2 Plugin permission audits

Quarterly (alongside the website's identity-health check):

- Run `/lp tree` in console → verify the permission tree matches the table above
- Run `/lp listgroups` → verify no unknown groups have been created
- Run `/lp listusers` → verify only intended people are in `admin`
- Save output to `docs/audits/permissions-YYYY-MM-DD.txt` (gitignored if it contains usernames)

### 7.3 Plugins that should NEVER be op-required

Some plugins request op-level permissions for routine commands. This is a smell. If a plugin asks Merric to op a friend just to use a feature, that's a no — find a different plugin or use LuckPerms permissions to grant the specific node.

### 7.4 RCON-using plugins

If a plugin uses RCON internally, it must connect to `localhost:25575` only. Any plugin requesting RCON over the network is rejected.

---

## 8. Plugin secrets handling

Plugins that need API keys, bot tokens, or other secrets:

- ✅ Token in `.env`, referenced from `docker-compose.yml` via env var substitution
- ✅ Token in the plugin's local config file, with the config file gitignored
- ❌ Token committed to the repo
- ❌ Token in a plugin config file mounted from a tracked path

### 8.1 Current secret-using plugins

- **DiscordSRV** — `BotToken` in `data/plugins/DiscordSRV/config.yml`. The whole `data/` directory is gitignored.

### 8.2 Rotation

If a secret leaks (committed by accident, posted publicly, etc.):

1. Revoke the secret immediately at the issuing service
2. Generate a new secret
3. Update the local config
4. Restart the affected service
5. Audit any actions taken with the old secret
6. Update SECURITY.md (when it exists) with the incident

---

## 9. References

- itzg/minecraft-server plugin documentation: https://docker-minecraft-server.readthedocs.io/en/latest/mods-and-plugins/
- Modrinth: https://modrinth.com
- PaperMC Hangar: https://hangar.papermc.io
- SpigotMC resources: https://www.spigotmc.org/resources/

---

## Changelog

- **v1.0** (2026-05-02) — Initial creation. 13 plugins in v1.1 starter pack across 4 tiers.

---

*"Treat plugins like production dependencies. They are."*
