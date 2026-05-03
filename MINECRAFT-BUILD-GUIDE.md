# MeteoricCraft — Build Guide (v1.1)

> The Minecraft server build for `merric-minecraft` repo, deployed on Shane's home workstation, exposed via playit.gg, status widget rendered on merricstrough.com/minecraft.
>
> **Stack:** Paper 1.21.11 + Geyser + Floodgate + 13-plugin starter pack, in Docker. playit.gg agent in same compose stack. Live status widget via Cloudflare Worker.
>
> **Companion documents** (read alongside this guide):
> - `docs/RUNBOOK.md` — day-to-day operations, change-management ladder, incident response
> - `docs/PLUGIN-GOVERNANCE.md` — plugin manifest, pinning policy, install/update/remove processes
> - `docs/CHILD-SAFETY-PRIVACY.md` — public/private data taxonomy, identity boundaries, moderation policy
> - `docs/decisions/` — ADRs documenting why each architectural choice was made
>
> **Why these choices:** see the ADRs, especially:
> - `ADR-0004` — Minecraft server architecture (overall stack)
> - `ADR-0005` — Network exposure strategy (playit.gg now, VPS later, never Cloudflare Tunnel for game traffic)
> - `ADR-0006` — Backup and restore strategy
> - `ADR-0007` — Plugin governance
> - `ADR-0008` — Child-safety and privacy boundaries

---

## What we're building

A real Minecraft server that:

- Runs **24/7** on Shane's home workstation (hardware/OS specifics in `CLAUDE.local.md`)
- Lets Bedrock (mobile, Windows 10/11) AND Java players join the same world via Geyser+Floodgate
  - **Console caveat:** Xbox, PlayStation, and Switch can join, but each requires a workaround setup (typically BedrockConnect — see Phase 5 below). Promise to console friends is "supported with a guide," not "zero-friction."
- Has a curated 13-plugin starter pack (anti-grief, economy, homes/warps, Discord event notifications, live web map, multi-world support)
- Exposes through **playit.gg** so Shane's home IP stays hidden (per ADR-0005)
- Reachable at `mc.merricstrough.com` (Java) and a Bedrock-specific address (Bedrock)
- Has a **live status widget** at https://merricstrough.com/minecraft showing player count (no names by default — see CHILD-SAFETY-PRIVACY.md §2.4), MOTD, online/offline state
- Has **automated daily world backups** (restic) with 7-day rolling retention (per ADR-0006)
- Is fully **infrastructure-as-code** in a Git repo — `git clone && docker compose up -d` and it runs again
- Has a **kid-friendly ops runbook** so Merric can manage day-to-day without Shane's help (per docs/RUNBOOK.md change-management ladder)

---

## Prerequisites checklist

Before starting, verify on the workstation:

```bash
docker --version          # must be 24.0+
docker compose version    # must be v2 (no hyphen)
git --version
restic version            # for automated backups; install if missing
```

If anything is missing:

```bash
# Docker (if not installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER  # log out and back in after this

# Restic (for backups)
sudo apt install restic
```

Confirm enough disk + RAM:

```bash
free -h                   # need at least 6GB free RAM (we cap server at 6GB)
df -h /                   # need at least 50GB free for world + plugins + backups
```

The 5090 rig has zero issue with this — both numbers should be many multiples over.

---

## Phase 0 — Repo setup

### 0.1 Create the GitHub repo

On Merric's GitHub (`MeteoricMetric`):

- New repo: `merric-minecraft`
- **Public** (so it counts toward his contribution graph and the ops doc is shareable)
- ☑ Add README
- ☑ Add `.gitignore` → choose **Node** template (we'll customize)
- License: MIT

### 0.2 Clone locally on the workstation

```bash
cd ~
git clone https://github.com/MeteoricMetric/merric-minecraft.git
cd merric-minecraft

# Use Merric's identity for this repo specifically
git config user.name "MeteoricMetric"
git config user.email "277578502+MeteoricMetric@users.noreply.github.com"
```

### 0.3 Drop in the build artifacts

Copy these files from this build session into the repo root:

```
merric-minecraft/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── CLAUDE.md
├── docs/
│   └── decisions/
│       └── ADR-0004-minecraft-server-architecture.md
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── update-plugins.sh
│   └── ops.sh
├── worker/
│   ├── src/
│   │   └── index.js
│   ├── wrangler.toml
│   └── package.json
└── plugins-config/
    └── (plugin configs we'll generate after first boot)
```

(Each artifact is provided as a separate file — paste contents in.)

### 0.4 Set up `.gitignore`

```gitignore
# Secrets — NEVER commit
.env
*.secret
*.key

# Server data — too large for git, lives on disk
data/
backups/

# OS junk
.DS_Store
Thumbs.db

# Editor noise
.vscode/
.idea/
*.swp

# Worker build artifacts
worker/node_modules/
worker/dist/
worker/.wrangler/
```

### 0.5 First commit

```bash
git add .
git commit -m "scaffold: initial repo structure"
git push
```

---

## Phase 1 — Configure environment

### 1.1 Copy `.env.example` to `.env`

```bash
cp .env.example .env
```

### 1.2 Edit `.env` — fill in real values

```bash
nano .env
```

Required values to set:

| Variable | What | How to get it |
|----------|------|---------------|
| `RCON_PASSWORD` | Admin remote console password | Generate: `openssl rand -base64 24` |
| `PLAYIT_SECRET_KEY` | playit.gg agent auth | Phase 3 — leave blank for now |
| `BLUEMAP_WEBSERVER_PASSWORD` | Web map admin password | Generate: `openssl rand -base64 16` |
| `OPS` | Comma-separated ops list (you + Merric) | Your Java usernames |
| `WHITELIST` | Comma-separated initial whitelist | You + Merric to start |

Everything else has sensible defaults — leave unless you want to tune.

### 1.3 Verify `.env` is gitignored

```bash
git status
# Should NOT show .env
```

If it shows up, **stop** and fix the `.gitignore` before doing anything else.

---

## Phase 2 — First boot (Minecraft only, no tunnel yet)

We're going to bring up just the Minecraft container first, verify it works locally, THEN add the tunnel.

### 2.1 Start the server

```bash
docker compose up -d mc
docker compose logs -f mc
```

**Watch the logs.** First boot takes 2–4 minutes because it:

1. Downloads Paper 1.21.11 (~50MB)
2. Downloads all 13 plugins
3. Generates the world (Chunky pre-generation kicks in)
4. Starts the JVM

You'll know it's ready when you see:

```
[Server thread/INFO]: Done (XX.Xs)! For help, type "help"
```

### 2.2 Test locally

From any Java Minecraft 1.21.11 client on the same LAN:

- Server address: `<your-workstation-LAN-IP>:25565`

You should connect, land in the world, and see "Welcome to MeteoricCraft" or whatever MOTD you set in `.env`.

If you can connect: ✅ Phase 2 complete. Stop the server and move to Phase 3.

```bash
docker compose stop mc
```

### 2.3 If it didn't work — diagnostics

```bash
docker compose logs mc | tail -100   # last 100 lines
docker compose ps                    # is it actually running?
```

Common issues:

- **"EULA not accepted"** → set `EULA=TRUE` in `.env`
- **"Can't bind to port"** → another Minecraft server is running locally; change port in compose
- **Plugin failed to load** → the plugin URL might be stale; check the plugin update script

---

## Phase 3 — playit.gg tunnel setup

### 3.1 Create a playit account

1. Go to https://playit.gg/account/setup/wizard/new-account/docker/docker-name
2. Sign up (use Shane's email — billing/admin)
3. Enable **2FA immediately** (required by CLAUDE.md §5.2)

### 3.2 Get the Docker agent secret key

The setup wizard will give you a Docker run command containing a `SECRET_KEY=...` value.

**Copy just the secret key value** (the long base64 string after `SECRET_KEY=`).

### 3.3 Add it to `.env`

```bash
nano .env
# set:
PLAYIT_SECRET_KEY=<paste the secret key here>
```

### 3.4 Start the playit agent

```bash
docker compose up -d playit
docker compose logs -f playit
```

You should see lines like:

```
playit-agent: connected
playit-agent: registered with playit.gg
```

### 3.5 Create the tunnels in the playit dashboard

Go to https://playit.gg/account/tunnels — click **Add Tunnel**.

**Tunnel 1 — Java:**
- Type: **Minecraft Java**
- IP option: Use Shared IP (free) — or Dedicated IP if you upgraded
- Region: Global Anycast
- Local IP: `127.0.0.1`
- Local Port: `25565`
- Click **Add Tunnel**

You'll get an address like `XXXX.gl.joinmc.link` — this is your **public Java server address**.

**Tunnel 2 — Bedrock:**
- Type: **Minecraft Bedrock**
- IP option: Use Shared IP
- Region: Global Anycast
- Local IP: `127.0.0.1`
- Local Port: `19132`
- Click **Add Tunnel**

You'll get a separate address with a port like `XXXX.gl.joinmc.link:19132`.

### 3.6 Test public connectivity

From an external network (your phone on cellular, or a friend):

- **Java client** → connect to `XXXX.gl.joinmc.link`
- **Bedrock client** (Merric's S23) → Servers tab → Add Server → use the bedrock address + port

If both connect: ✅ Phase 3 complete.

---

## Phase 4 — DNS at Porkbun

Map clean addresses to the playit hostnames.

### 4.1 Java: `mc.merricstrough.com`

Porkbun → merricstrough.com → DNS:

| Type | Host | Answer | TTL |
|------|------|--------|-----|
| CNAME | `mc` | `XXXX.gl.joinmc.link` | 600 |

Test in 5–10 min: connect to `mc.merricstrough.com` from a Java client. Should work identically.

### 4.2 Bedrock: `bedrock.merricstrough.com`

Bedrock is trickier — it needs the port to be specified, but DNS CNAMEs don't carry ports. Use an **SRV record**:

| Type | Host | Answer | Priority | Weight | Port | TTL |
|------|------|--------|----------|--------|------|-----|
| SRV | `_minecraft._udp.bedrock` | `XXXX.gl.joinmc.link` | 0 | 5 | `<bedrock-port>` | 600 |

**Note on Bedrock SRV records:** Some Bedrock clients still don't fully respect SRV. The bulletproof move is to give Bedrock players the raw playit address + port (`XXXX.gl.joinmc.link:<port>`). Add `bedrock.merricstrough.com` for completeness but document the raw fallback on the `/minecraft` page.

### 4.3 Update the website's `/minecraft` page

The merricstrough.com site already has a `/minecraft` route — Phase 6 below replaces the stub with a real status page, including these connection details.

---

## Phase 5 — Configure plugins

After first successful boot (Phase 2), the server has populated `data/plugins/` with default configs for all 13 plugins. Time to tune them.

### 5.1 LuckPerms — set up permission groups

Connect as op, then in-game:

```
/lp creategroup default
/lp creategroup trusted
/lp creategroup builder
/lp creategroup admin

/lp group default permission set essentials.spawn true
/lp group default permission set essentials.home true
/lp group default permission set essentials.sethome true

/lp group trusted parent set default
/lp group trusted permission set worldedit.use true

/lp group admin permission set * true

# Add Merric to admin
/lp user MeteoricMetric parent set admin
```

### 5.2 EssentialsX — sane defaults

Edit `data/plugins/Essentials/config.yml` (or via Pages CMS once we wire it up):

```yaml
sethome-multiple:
  default: 3
  trusted: 5
  admin: unlimited

teleport-cooldown: 3
teleport-delay: 0
back-on-death: true
```

### 5.3 CoreProtect — anti-grief logging

Edit `data/plugins/CoreProtect/config.yml`:

```yaml
default-radius: 10
api-enabled: true
disable-world-edit: false  # log WorldEdit operations too
```

Now any block break/place is logged. To roll back grief:

```
/co lookup u:<player> t:1d            # see their last 24h
/co rollback u:<player> t:1d r:50     # rollback their actions in 50-block radius
```

### 5.4 BlueMap — live web map

> BlueMap is **CPU-bound**, not GPU-accelerated. The tuning lever is render-thread count, not the workstation's GPU. The host has plenty of CPU cores to make this work, but the GPU isn't doing anything for BlueMap specifically.

Edit `data/plugins/BlueMap/core.conf` to accept the EULA:

```
accept-download: true
```

Then restart the server:

```bash
docker compose restart mc
```

BlueMap will start rendering tiles in the background using CPU threads. You can tune the render-thread count in BlueMap's config to match how aggressively you want it to use cores while the server is also running gameplay.

Live map will be available at:

- Local: `http://<workstation-LAN-IP>:8100`
- (Public access through playit + DNS comes in Phase 7 — separate tunnel)

> **Privacy note:** When BlueMap is published publicly (Phase 7), live player markers must be **disabled** per CHILD-SAFETY-PRIVACY.md §2.4. The map shows the world; it does not show who's currently online and where.

### 5.5 DiscordSRV — server event notifications

> **Privacy posture:** DiscordSRV is configured for **server-event notifications only** by default — joins, leaves, deaths, achievements appear as bot messages in a Discord channel. **Game chat is NOT bridged to Discord by default.** This is a deliberate child-safety choice per CHILD-SAFETY-PRIVACY.md §4. The upgrade path to bidirectional chat is documented but requires explicit decision.

Set up a Discord bot:

1. https://discord.com/developers/applications → New Application → name it "MeteoricCraft"
2. Bot → Add Bot → Reset Token → copy the token
3. OAuth2 → URL Generator → scopes: `bot` → permissions: `Send Messages, Read Messages, Manage Webhooks` → invite to your private Discord server
4. Add the token to `.env`:
   ```
   DISCORD_BOT_TOKEN=<paste here>
   DISCORD_CHANNEL_ID=<right-click channel in Discord → Copy ID>
   ```
5. Edit `data/plugins/DiscordSRV/config.yml` — these are the relevant settings to keep chat-bridge OFF:
   ```yaml
   BotToken: "${DISCORD_BOT_TOKEN}"
   Channels: {"global": "${DISCORD_CHANNEL_ID}"}

   # Keep these DISABLED for the event-notify-only posture:
   DiscordChatChannelDiscordToMinecraft: false
   DiscordChatChannelMinecraftToDiscord: false

   # Keep these ENABLED — server events are useful and low-risk:
   MinecraftPlayerJoinEnabled: true
   MinecraftPlayerLeaveEnabled: true
   MinecraftPlayerDeathEnabled: true
   MinecraftPlayerAchievementEnabled: true
   ```
6. Restart the server. You'll see joins, leaves, deaths, and achievements posted to Discord. In-game chat stays in-game.

**To upgrade to bidirectional chat bridge later** — read CHILD-SAFETY-PRIVACY.md §4.2 first. The upgrade requires a documented decision and an explicit conversation with Shane.

### 5.6 Chunky — pregenerate chunks

This makes the server WAY less laggy by generating chunks ahead of time.

In-game as op:

```
/chunky world world
/chunky radius 2000     # 2000 block radius from spawn = ~50k chunks
/chunky start
```

Will take 1-2 hours to complete. Set the world border to match:

```
/worldborder set 4000   # diameter, so 2000-radius
```

### 5.7 Console support — what to tell Xbox / PS / Switch friends

Console Bedrock players cannot directly enter a server address the way Java or mobile/Windows Bedrock players can. They need a workaround called **BedrockConnect**.

**The flow for a console friend:**

1. Player goes to https://bedrockconnect.us → notes the DNS server addresses listed there
2. Player sets that DNS in their console's network settings:
   - **Xbox:** Settings → Network → Network settings → Advanced settings → DNS settings → Manual → enter primary DNS
   - **Switch:** System Settings → Internet → Internet Settings → select your network → Change Settings → DNS Settings → Manual
   - **PlayStation:** Settings → Network → Setup Internet Connection → Custom → DNS Settings → Manual
3. Player launches Minecraft → Servers tab → BedrockConnect appears as a Featured Server
4. Player joins BedrockConnect, then uses its menu to enter our actual server address and port
5. After this initial setup, BedrockConnect remembers our server in the player's list

**Document this flow on the website.** The `/minecraft` page has a "Console support" section explaining it for friends; the build guide here is for Shane's reference.

**Caveats to communicate:**

- This is a community workaround, not an official Mojang feature. It works reliably but isn't endorsed by Microsoft.
- Some networks (school WiFi, corporate networks) block custom DNS — won't work there.
- Console friends can't link Java accounts; they're authenticating via their existing Microsoft/Xbox account.

**If a console friend struggles:** offer to get them on Bedrock via Windows 10/11 instead. The cross-platform progression carries over (same Microsoft account).

---

## Phase 6 — Live status widget on merricstrough.com/minecraft

This is the part that makes the website a real piece of infrastructure, not just a brochure.

### 6.1 Architecture

```
[merricstrough.com/minecraft] ←─ fetch JSON ─→ [Cloudflare Worker]
                                                       │
                                                  every 60s
                                                       ↓
                                          [mc.merricstrough.com:25565]
                                          via Minecraft Server List Ping protocol
```

The Worker:
- Polls the server every 60 seconds via SLP protocol
- Caches result in Cloudflare KV for 60s
- Returns JSON: `{ online, players, motd, version, latency_ms }`
- Same pattern as the Spotify Now Spinning worker — reuse the deployment workflow

### 6.2 Deploy the worker

Files in `worker/` directory of this repo (provided separately).

```bash
cd worker
npm install
npx wrangler login                    # opens browser, log in to Cloudflare
npx wrangler kv namespace create MC_STATUS_CACHE
# copy the namespace ID it prints, paste into wrangler.toml
npx wrangler deploy
```

Worker is now live at `https://merric-mc-status.<your-cf-subdomain>.workers.dev`.

Test it:

```bash
curl https://merric-mc-status.<...>.workers.dev/status
# {"online":true,"players":{"online":2,"max":20,"sample":[...]},"motd":"MeteoricCraft","version":"1.21.11","latency_ms":42}
```

### 6.3 Update the website's /minecraft page

In the `merricstrough.com` repo (this is a separate repo from `merric-minecraft`), promote the stub `/minecraft` route to a real page. See `worker/frontend-snippet.astro` (provided separately) for the exact component code.

The page will show:

- ✅ **Online indicator** — animated pulse, green when up, red when down
- 🎮 **Connection details** — `mc.merricstrough.com` for Java, the Bedrock address + port
- 👥 **Live player count** — refreshes every 60s on the page
- 💬 **MOTD** — the message of the day
- 📋 **Server rules** — markdown content editable via Pages CMS
- 🗺️ **BlueMap embed** — iframe showing the live web map (Phase 7)
- 📅 **"Updated"** timestamp — from the worker cache age

---

## Phase 7 — BlueMap public access (optional, do after Phase 6 is solid)

Make the live web map available at `map.merricstrough.com`.

> **Privacy precondition:** before publishing BlueMap, verify these settings in `data/plugins/BlueMap/maps/world.conf` (and equivalents for nether/end):
> - `marker-sets:` — empty (no live markers)
> - `live-players: false`
> - `live-marker-api: false` if using the BlueMap API plugin
>
> Per CHILD-SAFETY-PRIVACY.md §2.4. The public map shows terrain and structures; it does not show real-time player locations.

### 7.1 Create third playit tunnel

playit dashboard → Add Tunnel:
- Type: **TCP** (custom)
- Local IP: `127.0.0.1`
- Local Port: `8100`
- Add Tunnel

### 7.2 DNS

Porkbun:

| Type | Host | Answer |
|------|------|--------|
| CNAME | `map` | `<bluemap-tunnel-hostname>` |

### 7.3 Embed in `/minecraft` page

```html
<iframe
  src="https://map.merricstrough.com"
  loading="lazy"
  title="MeteoricCraft live map"
  style="width:100%;aspect-ratio:16/9;border:0;border-radius:var(--radius-lg);"
></iframe>
```

---

## Phase 8 — Automated backups

### 8.1 Initialize restic repository

Pick a backup target. Two good options:

**Option A — Local external drive (simplest):**

```bash
restic init --repo /mnt/<backup-volume>/minecraft-restic
# you'll be prompted for an encryption password — SAVE THIS
echo "<the-password>" > ~/.restic-password
chmod 600 ~/.restic-password
```

**Option B — Cloud (Backblaze B2 — ~$5/yr for this):**

```bash
export B2_ACCOUNT_ID=<your-b2-key-id>
export B2_ACCOUNT_KEY=<your-b2-app-key>
restic init --repo b2:<bucket-name>:/minecraft-restic
```

Add the credentials to `.env` (gitignored) and reference them in the backup script.

### 8.2 Set up the backup cron

```bash
# Copy the backup script
chmod +x scripts/backup.sh

# Edit your crontab
crontab -e
```

Add this line:

```cron
# Every day at 3am — backup Minecraft world
0 3 * * * /home/$USER/merric-minecraft/scripts/backup.sh >> /home/$USER/merric-minecraft/logs/backup.log 2>&1
```

### 8.3 Test the backup right now

```bash
./scripts/backup.sh
```

Should output: `snapshot abc123def saved` and complete in ~30s for a fresh world.

### 8.4 Verify retention is working

After 8 days, you should have exactly 7 snapshots (oldest pruned automatically by the script).

```bash
./scripts/backup.sh   # the script also handles pruning
restic snapshots --repo /mnt/<backup-volume>/minecraft-restic
```

### 8.5 Practice a restore (DO THIS ONCE — and then on a quarterly cadence forever)

A backup you've never restored is not a backup. While Merric is around — practice it together. He'll learn AND he'll know it works:

```bash
./scripts/restore.sh
# follow the interactive prompts
```

**Quarterly restore drill cadence** (per ADR-0006 and RUNBOOK.md §3):

This is not a one-time check. It's a recurring discipline. Calendar dates aligned with the website repo's existing scheduled audits:

- 2026-08-01 (next)
- 2026-11-01
- 2027-02-01
- 2027-05-01

Each drill follows the procedure in RUNBOOK.md §3.3 (restore to a sandbox path, verify, tear down). The drill outcome is recorded in `docs/audits/restore-drill-YYYY-MM-DD.md` so we have a history of recoverability.

Why quarterly? Backup integrity issues are sometimes silent — restic might say "snapshot saved" while a corrupt block goes undetected. The drill is the only thing that catches that before it matters.

---

## Phase 9 — Ops handover to Merric

Now the server is running, time to hand him the keys for day-to-day operations.

> **First, read RUNBOOK.md §1 together.** The change-management ladder defines what's 🟢 safe alone, 🟡 safe with Dad nearby, and 🔴 adult-only. It's the framework for everything below.

### 9.1 The kid-friendly ops cheatsheet (🟢 safe alone)

Print this and tape it to his wall (or pin in his Discord):

```
═════════════════════════════════════════
  METEORICCRAFT OPS CHEATSHEET
═════════════════════════════════════════

START THE SERVER
  cd ~/merric-minecraft && docker compose up -d

STOP THE SERVER
  docker compose down

RESTART THE SERVER
  docker compose restart mc

CHECK IF IT'S RUNNING
  docker compose ps

WATCH WHAT'S HAPPENING (live console)
  docker compose logs -f mc
  (Ctrl+C to exit, doesn't stop the server)

ADD A FRIEND TO THE WHITELIST
  In-game as op, type:  /whitelist add <username>
  Or via the Pages CMS form once that's wired

SEE WHO'S ONLINE
  In-game:  /list

TELEPORT YOURSELF
  /tp <player>          (to a player)
  /home                 (to your home)
  /sethome              (set new home)
  /spawn                (back to spawn)

KICK SOMEONE BEING A PROBLEM
  /kick <player> <reason>

BACKUP NOW (manual, before something risky)
  ./scripts/backup.sh

ROLLBACK GRIEF (CoreProtect)
  /co lookup u:<player> t:1d
  /co rollback u:<player> t:1d r:50

═════════════════════════════════════════
```

### 9.2 The "you broke it, fix it" runbook

For when things go sideways. Order of operations:

1. **Check it's actually broken**: `docker compose ps`
2. **Read the last 50 lines of logs**: `docker compose logs --tail 50 mc`
3. **Restart the container**: `docker compose restart mc`
4. **If it won't start**: post the error in the family Discord, ping Shane
5. **If the world is corrupted**: `./scripts/restore.sh`
6. **Last resort**: rollback to last known good — Shane has the recovery codes / backup access

### 9.3 The weekly habit

Every Sunday evening (when Shane and Merric do their weekly review):

- [ ] Server still online?  `curl https://merric-mc-status.workers.dev/status`
- [ ] Disk space OK?  `df -h /`
- [ ] Backups completing?  `tail logs/backup.log`
- [ ] Plugin updates available?  `./scripts/update-plugins.sh --dry-run`
- [ ] Any concerning console messages from the week?  `docker compose logs --since 7d mc | grep -i 'error\|warn'`

---

## Phase 10 — Document and ship

### 10.1 ADRs in the website repo's `docs/decisions/`

The Minecraft project introduces five ADRs (one preexisting, four new in v1.1). Copy these into the **website repo** so the architectural decision history lives alongside the rest of the project:

```bash
# in C:\Users\shane\merricstrough-com
git pull
mkdir -p docs/decisions

# Copy ADRs from the merric-minecraft repo
cp <merric-minecraft-path>/docs/decisions/ADR-0004-minecraft-server-architecture.md docs/decisions/
cp <merric-minecraft-path>/docs/decisions/ADR-0005-network-exposure-strategy.md docs/decisions/
cp <merric-minecraft-path>/docs/decisions/ADR-0006-backup-restore-strategy.md docs/decisions/
cp <merric-minecraft-path>/docs/decisions/ADR-0007-plugin-governance.md docs/decisions/
cp <merric-minecraft-path>/docs/decisions/ADR-0008-child-safety-privacy-boundaries.md docs/decisions/

git add docs/decisions/
git commit -m "docs: ADRs 0004-0008 — minecraft architecture, network, backup, plugins, safety"
git push
```

The ADRs in the website repo serve as the architectural canon for the whole project. The full **policy docs** (`PLUGIN-GOVERNANCE.md`, `CHILD-SAFETY-PRIVACY.md`, `RUNBOOK.md`) stay in the merric-minecraft repo, with the ADRs cross-referencing them.

### 10.2 Update the website's CLAUDE.md project state

In the website repo, edit `CLAUDE.md` Section 14:

```markdown
**Current status (updated <date>):**
- ✅ MeteoricCraft Minecraft server live (Paper 1.21.11 + Geyser, Docker on workstation)
- ✅ playit.gg tunnel: mc.merricstrough.com (Java) + Bedrock address (Bedrock)
- ✅ Cloudflare Worker serving status JSON (sanitized — count only, not names by default)
- ✅ /minecraft page upgraded from stub to real status page with rules & connection info
- ✅ BlueMap web map at map.merricstrough.com (live player markers OFF per privacy policy)
- ✅ Daily restic backups, 7-day rolling retention; quarterly restore drills scheduled
- ✅ Plugin governance: 13-plugin starter pack with manifest, pinning policy, install/update/remove processes
- ✅ Child-safety policy explicit: public/private data taxonomy, hostname identity boundaries, moderation ladder
- ✅ DiscordSRV configured for event notifications only (chat bridge deferred per policy §4)
- ✅ Console support documented (BedrockConnect workflow for Xbox/PS/Switch friends)
- ✅ Ops runbook with change-management ladder (🟢 / 🟡 / 🔴 tiers)
- ✅ ADRs 0004-0008 in docs/decisions/ documenting all architectural choices
```

### 10.3 Tell people

This is Merric's victory lap. Drop a Discord message to friends:

> **MeteoricCraft is live.**
> Java: `mc.merricstrough.com`
> Bedrock: `XXXX.gl.joinmc.link` port `<port>`
> Whitelist's open — DM me your username
> Live map: https://map.merricstrough.com
> Status & rules: https://merricstrough.com/minecraft

---

## What this gives him

When Merric tells his friends "I run a Minecraft server," 99% of kids his age mean "I clicked Aternos." What he actually has:

- Real infrastructure-as-code, version-controlled
- Cross-platform play (mobile and Windows Bedrock friends + Java friends + console friends with a documented workaround)
- A live map, Discord-event-bridged, with privacy boundaries enforced by policy
- Automated backups, monitored uptime, structured plugin permissions
- A quarterly restore-drill discipline so backups are real, not theoretical
- A status page on his real domain that updates live without leaking player identities
- Architectural decisions written down in 5 ADRs and explained with alternatives
- Three living policy documents (governance, safety, runbook) keeping the system principled
- A change-management ladder so he knows what's safe to do alone vs with help
- Skills he just learned (Docker, DNS, env files, cron, restic, RCON, Cloudflare Workers, LuckPerms, plugin governance)

That's an absurd skill stack for a 13-year-old. And every piece of it will still be useful 20 years from now.

---

## Future enhancements (deferred — list, not commitments)

- **VPS + WireGuard edge** — when triggered by the trigger events in ADR-0005 (player count, public discoverability, playit reliability concerns, Shane's move from FL to CO, etc.)
- **Off-site backup target** — Backblaze B2 in Phase 2, completing the 3-2-1 design (per ADR-0006)
- **Project-identity domain** — register `meteoriccraft.com` for cheap optionality if the server ever broadens beyond friends (per CHILD-SAFETY-PRIVACY.md §3.1)
- **DiscordSRV chat bridge upgrade** — bidirectional chat, only after the preconditions in CHILD-SAFETY-PRIVACY.md §4.2 are met and a documented decision exists
- **Simple Voice Chat** plugin for proximity voice in-game (CHILD-SAFETY-PRIVACY.md and PLUGIN-GOVERNANCE.md updates first)
- **Whitelist via Pages CMS** — Merric adds friends through a form, not a command
- **Discord slash commands** for ops actions (`/mcstatus`, `/whitelist add`)
- **Cosmetic minigame plugins** (Citizens NPCs, MythicMobs) once the survival core is dialed
- **A second world (creative)** via Multiverse-Core for build practice
- **Prometheus metrics** + Grafana dashboard for Shane's monitoring stack — needs one more verification pass on which Minecraft-to-Prometheus exporter to trust
- **Local AI "LoreBot/Warden"** — read-only by default, Ollama on the workstation, narrow tool scope, parent override; documented in a future ADR-0010 if pursued
- **Promote `/minecraft` to its own subdomain repo** (`merric-minecraft-site`) when content justifies extraction (per merricstrough.com CLAUDE.md §3.3)

---

*Built by Shane & Merric, with Claude. May 2026. Version 1.1.*

*"This server isn't just for fun — it's the proof of what we can build together when we treat our toys like real things."*
