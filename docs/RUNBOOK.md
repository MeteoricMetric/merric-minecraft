# Runbook

> Operational reference for MeteoricCraft. How to do things, when to do them, who does them, and what to do when things break.

**Owner:** Shane Strough  
**Operator:** Merric Strough (`MeteoricMetric`)  
**Companion docs:** [CHILD-SAFETY-PRIVACY.md](CHILD-SAFETY-PRIVACY.md), [PLUGIN-GOVERNANCE.md](PLUGIN-GOVERNANCE.md), [MERRIC-OPS-MANUAL.md](MERRIC-OPS-MANUAL.md), [PLAYER-GUIDE.md](PLAYER-GUIDE.md)

> Per [ADR-0010](decisions/ADR-0010-public-economy-server-format.md), the server is no longer whitelist-gated. Whitelist commands remain available for emergency lockdown only. Day-to-day moderation runs on CoreProtect rollback + anti-combat-log + GriefPrevention claims + dual-admin authority.

---

## 1. Change-management ladder

Every operation on the server falls into one of three tiers based on **blast radius** and **reversibility**.

### 1.1 🟢 Safe alone (Merric can do these unsupervised)

These are everyday operations with limited blast radius and easy recovery if something goes sideways.

| Operation | Command | Notes |
|---|---|---|
| Start the server | `./scripts/ops.sh start` | Idempotent — safe to run if already started |
| Stop the server | `./scripts/ops.sh stop` | Always graceful; players warned via plugin |
| Restart the server | `./scripts/ops.sh restart` | Use after a config change |
| Check status | `./scripts/ops.sh status` | Read-only |
| Watch logs | `./scripts/ops.sh logs` | Read-only |
| See who's online | `./scripts/ops.sh online` | Read-only |
| Run a manual backup | `./scripts/ops.sh backup` | Always safe, never harmful |
| Kick a misbehaving player | `/kick <name> <reason>` | They can rejoin |
| In-game commands as op | `/tp`, `/give`, `/gamemode`, `/time`, `/weather` | Affects only Merric's gameplay or limited scope |
| Spawn a custom boss | `/mm spawn CosmicKnight 1` (or `MagmaSentinel`, `VoidReaver`) | MythicMobs; despawns after kill |
| Issue a crate key | `/crates give physical <Tier> <amount> <player>` | Tier ∈ {Common, Rare, Legendary}; case-sensitive |
| Inspect/rollback grief | `/co inspect`, `/co lookup u:<name> t:1d`, `/co rollback u:<name> t:1d r:50` | CoreProtect — see §2.5 |
| Edit MOTD | Edit `MOTD=` in `.env` and restart | MOTD content reviewed per CHILD-SAFETY-PRIVACY.md §2.1 |
| Edit server rules | Edit content; commit | Public-facing rules stay aligned with policy |
| Emergency lockdown (whitelist on) | `/whitelist on` → `/whitelist add <trusted>` per name | Per ADR-0010: only during active incident; restore-state once resolved |

### 1.2 🟡 Safe with Dad nearby (do these together)

These have larger blast radius or interact with infrastructure beyond the game.

| Operation | Command | Why "with Dad" |
|---|---|---|
| Add a new plugin | Edit `docker-compose.yml`, restart | Plugin governance review (PLUGIN-GOVERNANCE.md §4) |
| Update plugins | `./scripts/ops.sh update` | Could break things; backup first |
| Change resource limits | Edit `deploy.resources` in compose | Could affect other workloads on the workstation |
| Modify the LuckPerms permission tree | `/lp` commands | Easy to lock yourself out if mistyped |
| Restore from backup | `./scripts/ops.sh restore` | Destructive — overwrites current world |
| Re-tune a custom boss | Edit `data/plugins/MythicMobs/Mobs/CustomBosses.yml`, `/mm reload` | Bad numbers can make a boss un-killable or trivial |
| Edit a crate's loot table | Edit `data/plugins/CrazyCrates/crates/<Tier>.yml`, `/crates reload` | Wrong syntax = crate breaks for everyone |
| Adjust GriefPrevention defaults | Edit `data/plugins/GriefPrevention/config.yml` | Affects every claim — easy to lock players out of land |
| Configure DiscordSRV | Edit `data/plugins/DiscordSRV/config.yml` | Privacy boundary (CHILD-SAFETY-PRIVACY.md §4) |
| Change BlueMap settings | Edit BlueMap config | Privacy boundary (markers off, see §4) |
| Pre-generate chunks | `/chunky start` | Long-running; affects performance |
| Manually edit world files | Anything in `data/world/` | Could corrupt the world |

### 1.3 🔴 Adult-only (Shane only)

These touch credentials, network exposure, or have potential for irreversible harm.

| Operation | Why adult-only |
|---|---|
| Edit `.env` (RCON password, secrets) | Credential management |
| Edit `wrangler.toml` (Cloudflare Worker) | Cloudflare account access |
| `wrangler deploy` (push worker) | Affects the live website |
| Add/change DNS records at Porkbun | Domain registrar access |
| Configure playit.gg tunnels | Account credentials, public exposure |
| Set up new restic repository | Encryption password choice |
| Initial Backblaze B2 setup | Billing account |
| Branch protection / GitHub repo settings | Repo admin permissions |
| Modify this runbook's tier assignments | Policy decision |
| Approve a Tier-5 (watchlist) plugin promotion | Policy decision |
| Ban a player at Severity 3+ (per CHILD-SAFETY-PRIVACY.md §5.2) | Moderation authority |
| Take the server offline for an extended period | Communication with friends |
| Decide to make the server publicly discoverable | Major policy change |

---

## 2. Common incidents

### 2.1 Server won't start

**Symptoms:** `./scripts/ops.sh start` returns; container shows `Exited` in `./scripts/ops.sh status`.

**Triage:**

```bash
./scripts/ops.sh logs --tail 100
```

**Common causes:**

| Log message | Cause | Fix |
|---|---|---|
| `EULA must be accepted` | EULA not set | `EULA=TRUE` in `.env` |
| `Address already in use` | Another process on port 25565 | `sudo lsof -i :25565` to find it; stop it |
| `Could not load plugin` | Bad plugin URL or incompat version | Remove the plugin from compose, restart |
| `OutOfMemoryError` | RAM cap too low | Bump `MEMORY=` in `.env` (within compose limits) |
| `Failed to load world data` | Possible world corruption | Restore from last backup (Tier 🟡 — with Dad) |
| `Unable to access jarfile` | Paper download failed | Check internet; try `docker compose pull` then restart |

**Tier:** Triage is 🟢 Safe alone (read-only). Fix may escalate.

### 2.2 Server is laggy / players complain about TPS

**Triage:**

In-game as op:
```
/spark profiler --timeout 60
```

Wait 60 seconds, copy the URL it prints. Open it — Spark shows what's eating CPU.

**Common causes:**

- Too many entities (mob farms, item drops) — find with `/spark` or `/lagg gui` if installed
- Chunk loading thrash — check with BlueMap or `/chunky`
- Plugin gone wild — Spark identifies the offender
- Workstation under load from another process (AI training etc.) — check `htop` outside the container

**Fix:** depends on cause. Most fixes are 🟡 Tier (with Dad).

### 2.3 Bedrock players can't connect

**Triage checklist:**

1. Java players can connect? → If no, see §2.1
2. The Geyser plugin loaded? → `./scripts/ops.sh logs | grep -i geyser`
3. The Bedrock playit tunnel is up? → playit dashboard
4. The address Bedrock player is using includes the port? → `XXXX.gl.joinmc.link:<port>`
5. The player's Bedrock client version is current? → Bedrock auto-updates; if they're an Xbox player, see §2.4

### 2.4 Console player (Xbox / Switch / PS) can't connect

Symptom is almost always "the server never shows up to add" — consoles block custom server addresses by default (per CHILD-SAFETY-PRIVACY.md §3 noted limitation). If Java or phone-Bedrock players are on, the server itself is fine; this is purely a console-client limitation. Two fixes, easiest first:

1. **Point them at a phone / tablet / PC.** A phone, tablet, or Windows 10/11 PC adds a custom server normally (Servers → Add Server → `mc.merricstrough.com` port `47785`). No DNS hacks, it saves to their list, most child-safe. Recommend this first — especially for kids.
2. **Console — BedrockConnect DNS workaround:**
   1. On the console, set Manual DNS → Primary `104.238.130.180`, Secondary `8.8.8.8`.
   2. Launch Minecraft → **Servers** tab → tap *any* Featured Server (The Hive, Lifeboat, …). The DNS redirects it to a BedrockConnect menu.
   3. In that menu: "Connect to a Server" → `mc.merricstrough.com`, port `47785`.
   - The DNS step repeats each session (consoles won't save a custom server). Some networks block the IP — GeyserMC notes the main IP is "often blocked on consoles." If it won't load, fall back to option 1.
   - Source of truth for current/regional IPs: https://github.com/Pugmatt/BedrockConnect — the old `https://bedrockconnect.us` site was unreachable as of 2026-06-09, but the public DNS at `104.238.130.180` was verified live and redirecting featured-server hostnames that day.
   - Privacy: that DNS routes the console's lookups through a third party while set — revert to Automatic after playing (relevant per CHILD-SAFETY-PRIVACY.md).

This is documented for players on the website's `/minecraft` page and in PLAYER-GUIDE.md (console footnote).

### 2.5 Someone griefed something

1. Identify the affected area
2. Identify the player (witness, screenshot, or `/co inspect` to scan a block's history)
3. Lookup their actions:
   ```
   /co lookup u:<player> t:1d
   ```
4. Roll back:
   ```
   /co rollback u:<player> t:1d r:50
   ```
   (radius 50 from current location)
5. Apply moderation per CHILD-SAFETY-PRIVACY.md §5.2

### 2.6 Workstation rebooted unexpectedly

The compose stack has `restart: unless-stopped` so containers come back automatically. But:

1. Check status: `./scripts/ops.sh status`
2. If anything is `Exited`, run `./scripts/ops.sh start`
3. Check the world isn't corrupted: connect, look around, check that recent builds are still there
4. If anything's missing, restore from last backup

### 2.7 Backup didn't run

The cron entry posts to `logs/backup.log`. Check:

```bash
tail -50 logs/backup.log
```

Common causes:
- Disk full at the backup target
- Restic repository password file missing
- Restic version mismatch after Ubuntu update

Fix and rerun:
```bash
./scripts/ops.sh backup
```

### 2.8 The `/minecraft` status page shows offline but the server is online

Likely the Cloudflare Worker can't reach the server.

1. Test the worker directly: `curl https://merric-mc-status.<sub>.workers.dev/status`
2. If it returns `online: false` with an error, the server's not reachable from Cloudflare — could be playit tunnel down, DNS issue, or Worker can't make TCP outbound
3. Test from another external network: try connecting from a phone on cellular to `mc.merricstrough.com:25565`
4. If the server is reachable externally but the Worker can't reach it: check `wrangler tail` for the error

This is 🟡 Tier — likely needs Shane.

### 2.9 Discord bridge spamming or misbehaving

1. In Discord: temporarily revoke the bot's send permission in the channel (no service interruption to the server)
2. Investigate the cause — usually a config change or a Discord webhook loop
3. Fix and re-enable

### 2.10 Player claims someone said/did something serious

See CHILD-SAFETY-PRIVACY.md §5.5. Always tell Shane, even if it seems small.

### 2.11 GriefPrevention: a player can't claim land or got stuck inside someone else's claim

**"I can't claim — says I have no blocks":**
- Check their balance: `/acb <player>` (admin-claim-blocks). New players get **100 starter blocks**, +100/hr playtime, capped at 5000.
- Grant blocks if needed: `/acb <player> add 1000`
- Verify they're holding the **golden shovel** (claim tool) when right-clicking the diagonal corners

**"I'm trapped inside another player's claim":**
- Tell them to use `/spawn` (always allowed, even from inside a claim)
- If `/spawn` is blocked by a config bug: `/tp <player> <safe-coords>` from console, then file an issue

**"They claimed land they shouldn't have / squatting near my base":**
- Inspect: `/abandonclaim` requires standing inside it; admins can use `/adminclaims` to list
- Last resort: `/deletclaim` while standing in it (admin-only). Tell the player first if at all possible — claim deletion is destructive to their work.

### 2.12 Custom boss feels broken

**Symptoms:** boss un-killable, boss instantly dies, boss not spawning naturally, abilities not firing.

**Triage:**
1. `/mm reload` — picks up any config edits without server restart
2. Check `data/plugins/MythicMobs/Mobs/CustomBosses.yml` for syntax errors (YAML — indentation matters)
3. Look at the server log for "Couldn't load mob X" lines after reload
4. Spawn one manually with `/mm spawn <name> 1` and watch it — does it use abilities?

**Common causes:**
- Skill file (`Skills-MeteoricSkills.yml`) and Mob file out of sync — referenced skill name doesn't exist
- Drop table reference broken — boss kills produce no loot
- `Faction:` or `Type:` typos make the mob fail to register

Re-tuning HP / damage / ability frequency = 🟡. Adding new bosses = 🟡 with PLUGIN-GOVERNANCE-style review.

---

## 3. Restore drills

### 3.1 Why drills

A backup that's never been restored is not a backup. The drill catches:
- Backup corruption (sometimes silent)
- Missing files in the backup set
- Restore script bugs
- Steps you've forgotten how to execute

### 3.2 Drill cadence

**Quarterly** — aligned with the website repo's existing scheduled audits (next dates inherited from website calendar). Suggested calendar: 2026-08-01, 2026-11-01, 2027-02-01, 2027-05-01.

### 3.3 Drill procedure

**Environment variables (set on the host before running restic commands):**
```bash
export RESTIC_REPOSITORY=/mnt/<backup-volume>/minecraft-restic   # see CLAUDE.local.md for real path
export RESTIC_PASSWORD_FILE=/home/<user>/.restic-password
```
The restic binary lives at `~/bin/restic` (no-sudo install); `~/.bashrc` puts it on `PATH`.

1. **Don't restore over production.** Use a disposable directory.
2. Pick a snapshot from `restic snapshots` — ideally a few days old (not the freshest)
3. Restore to a sandbox path:
   ```bash
   restic restore <snapshot-id> --target /tmp/restore-drill-$(date +%Y%m%d)
   ```
4. Verify:
   - `data/world/` exists and is non-empty
   - `data/plugins/` contains expected jars
   - `data/server.properties` looks right
   - File timestamps are reasonable
5. (Optional) Spin up a test container pointing at the restored data, on a different port:
   ```bash
   # docker run --rm -it -e EULA=TRUE -p 25566:25565 -v /tmp/restore-drill-...:/data itzg/minecraft-server:java25
   ```
6. Connect, look at the world, verify spawn point + a known landmark (the spawn meteor pillar at 0,100,0; the duels arena at 100,70,100)
7. Tear down the test container
8. `rm -rf /tmp/restore-drill-...`
9. Record the drill outcome in `docs/audits/restore-drill-YYYY-MM-DD.md`

### 3.4 Drill record template

```markdown
# Restore drill — YYYY-MM-DD

- Snapshot ID: abc123def
- Snapshot date: YYYY-MM-DD HH:MM:SS UTC
- Drill date: YYYY-MM-DD
- Drill duration: X minutes
- Restore target: /tmp/restore-drill-...

## Outcome
- [ ] Restore completed without error
- [ ] All expected files present
- [ ] World loadable in test container
- [ ] Spawn point intact
- [ ] Known landmark visible

## Issues
(none / list)

## Action items
(none / list)

## Operator: Shane / Merric / both
```

---

## 4. Pre-change checklist

Before any 🟡 or 🔴 tier change:

- [ ] Is now a good time? (No friends actively playing, or warned them in advance)
- [ ] Have I run `./scripts/ops.sh backup` in the last hour?
- [ ] Do I know how to roll back if this fails?
- [ ] Will this affect the website's `/minecraft` page? (If yes, plan messaging)
- [ ] Is this documented in advance, so I'm not improvising?
- [ ] Am I doing this because I should, or because I can?

If any "no" → reconsider.

---

## 5. Post-incident review

After any unplanned event (server down, grief, unexpected behavior, security concern):

### 5.1 Within 24 hours

Capture facts while they're fresh. Use `docs/INCIDENTS.md` (create if doesn't exist):

```markdown
## Incident YYYY-MM-DD: <short title>

### What happened
(Plain English summary)

### Timeline
- HH:MM — first sign of issue
- HH:MM — investigation started
- HH:MM — cause identified
- HH:MM — resolved

### Cause
(Root cause if known, hypothesis if not)

### Impact
- Who/what was affected
- For how long
- Data loss? Y/N

### What we did
(Steps taken, in order)

### What we should change
- [ ] Action 1
- [ ] Action 2

### Documented by
Shane / Merric / both
```

### 5.2 Within 7 days

For severity 🔴 incidents (data loss, security exposure, child-safety event):

- Root cause analysis
- Specific changes to prevent recurrence
- Update relevant policy docs (CHILD-SAFETY-PRIVACY, PLUGIN-GOVERNANCE, this RUNBOOK)
- Brief Shane and Merric together on what changed and why

---

## 6. Weekly habit

Every Sunday evening, alongside the website's weekly review:

- [ ] `./scripts/ops.sh status` → all healthy?
- [ ] `df -h /` → workstation has plenty of disk?
- [ ] `tail -50 logs/backup.log` → backups completing?
- [ ] Any concerning log messages from the week? (`docker compose logs --since 7d mc | grep -iE 'error|warn|fail'`)
- [ ] Plugin updates pending? (Tier 2-3 are bundled; Tier 1 individually evaluated)
- [ ] Anything Merric wants to do this coming week that I should plan around?

---

## 7. Cross-references

- `merricstrough.com/CLAUDE.md` §11 (Performance) — backup is also part of recovery posture
- `merric-minecraft/CLAUDE.md` — Claude Code conventions for editing this repo
- `merric-minecraft/MINECRAFT-BUILD-GUIDE.md` — initial build steps; this runbook is for ongoing operations
- `merric-minecraft/docs/CHILD-SAFETY-PRIVACY.md` — what the rules are
- `merric-minecraft/docs/PLUGIN-GOVERNANCE.md` — how plugins get added/changed
- `merric-minecraft/docs/decisions/` — ADRs documenting why decisions were made

---

## Changelog

- **v1.0** (2026-05-02) — Initial creation as part of merric-minecraft v1.1.
- **v1.1** (2026-05-09) — v1.3 stack alignment: removed whitelist add/remove rows (per ADR-0010); added boss-spawn / crate-key / CoreProtect rollback to 🟢 row; added boss-tune / crate-edit / GriefPrevention 🟡 rows; new incidents §2.11 (GriefPrevention) and §2.12 (broken boss); restore drill updated for `~/bin/restic` install and `java25` image; cross-refs to MERRIC-OPS-MANUAL and PLAYER-GUIDE.

---

*"Operations is the practice of staying calm while doing reversible things to a stable system, on purpose."*
