# Child-Safety & Privacy Policy

> The MeteoricCraft server hosts a minor's public-facing identity. This document defines what is acceptable to expose, what stays private, and how decisions get made when that line is unclear.
>
> This policy is binding on every component of the system: the game server, the website's `/minecraft` page, the Cloudflare Worker, the BlueMap web map, the Discord integration, automated agents, and any future AI features.

**Owner:** Shane Strough  
**Operator:** Merric Strough (`MeteoricMetric`)  
**Companion ADR:** [ADR-0008](decisions/ADR-0008-child-safety-privacy-boundaries.md)  
**Companion master policy:** `merricstrough.com` CLAUDE.md §5 (Security) and §10 (Cross-site identity)

---

## 1. Guiding principles

1. **Default closed.** When a data-exposure decision is unclear, the answer is "do not expose." Add later, never roll back.
2. **Operator safety over server features.** A cool feature that requires exposing a minor's identifying data does not get shipped. Period.
3. **The whitelist is the perimeter.** The server stays whitelist-only by default. Public discoverability is a separate, deliberate decision with a different threat model.
4. **The website is the public face. The server is private infrastructure.** Cross-references between the two should be intentional and minimal.
5. **Parent override always wins.** Shane has unilateral authority to remove content, ban users, take the server offline, or change any policy at any time, with no procedural delay.

---

## 2. Data taxonomy — what is public, what is private

### 2.1 PUBLIC (acceptable on the website, status widget, public BlueMap, public Discord embeds)

| Data class | Examples | Notes |
|---|---|---|
| Server liveness | `online`, `offline`, `starting up`, last status timestamp | Drives the pulse indicator |
| Aggregate counts | "3 / 20 players online" | Numerical only; no names |
| Server identity | `MeteoricCraft`, sanitized MOTD | MOTD is reviewed for content before each change |
| Server version | `Paper 1.21.11`, protocol version | Public for client compatibility |
| Connection address | `mc.merricstrough.com`, Bedrock address + port | Required for friends to connect |
| Server rules | The published rules text | Same content the players see in-game |
| Curated screenshots | Hand-picked builds, landscapes, structures | Reviewed; no usernames visible in chat overlays |
| Architectural docs | This policy, ADRs, the build guide | Educational; public by design |

### 2.2 PRIVATE (never exposed via public surfaces — NOT website, NOT public Discord, NOT public BlueMap)

| Data class | Examples | Why |
|---|---|---|
| Player usernames (sample list) | The `players.sample` field from server pings | Publishing identifies who is online right now |
| Player IPs | Connection logs, RCON output | PII; doxxing risk |
| Player UUIDs | XUIDs, Java UUIDs | Cross-platform tracking risk |
| Chat logs | In-game chat, Discord-bridged chat | Conversational privacy |
| Coordinates of player builds | World positions, region claims | Real-world stalking facilitator if combined with usernames |
| Live player markers on BlueMap | Real-time location dots | If BlueMap is published, markers are OFF |
| Backup paths and providers | `/mnt/<backup-volume>/...`, B2 bucket names | Reduces attack surface |
| Server console output | Logs, stack traces, plugin debug | May contain credentials, IPs, PII |
| Whitelist contents | List of approved usernames | Reduces social engineering of friends |
| Operator commands and admin actions | Op grants, kicks, bans | Privacy of moderation decisions |
| Plugin secret configurations | Discord bot tokens, RCON passwords, API keys | Self-evident |
| Internal monitoring dashboards | Grafana, Prometheus, Alertmanager | Not for public consumption |

### 2.3 INTERNAL — visible to Shane and Merric only

| Data class | Examples | Access mechanism |
|---|---|---|
| Console & RCON | Live server console | `./scripts/ops.sh console` (localhost only) |
| Server logs | Filesystem, container logs | `./scripts/ops.sh logs` |
| Player IPs | Server-side log entries | Not surfaced to Merric routinely; only Shane reviews when needed |
| Backup archives | Encrypted restic snapshots | Restore drills only; not browsed casually |

### 2.4 The `players.sample` field — special handling

The Cloudflare Worker that powers the status widget receives a `players.sample` field in the SLP response. This is a list of currently-online usernames.

**Default policy:** the sample list is **NOT exposed** on the public `/minecraft` page. The page shows the count and a label like "3 players online" without names.

**Override:** if Merric chooses to display names (e.g., "showing my friends are on right now"), this requires:
1. Explicit conversation with Shane about why
2. Update to this policy with a documented decision
3. Update to the Worker config and frontend
4. Whitelist-only enforcement still required (these are friends, not strangers)

The Worker code already filters this: see `worker/src/index.js` — the response includes `players.sample` only because that's the Minecraft protocol. The frontend is responsible for showing or hiding it. Default frontend hides it.

---

## 3. Identity boundaries

### 3.1 Server hostname vs operator identity

**Current state:** The join address is `mc.merricstrough.com`, which centers Merric's surname in the public-facing connection string.

**Acceptable for:** A whitelist-only server with no public discovery, no streaming, no advertising.

**Becomes a concern when:** The server is mentioned in any public Discord, posted on social media, embedded in YouTube/Twitch streams, or otherwise advertised to people outside the whitelist.

**Mitigation already in place:**
- Register `meteoriccraft.com` (~$10/yr) as a project-identity domain. *Not yet done — recommended action.*
- If the server ever broadens beyond friends, switch the public join address to `play.meteoriccraft.com`. The `mc.merricstrough.com` CNAME can stay live for backward compatibility but the publicly-promoted address uses the project identity.

**Decision rule:** if the server is going to be mentioned in any public-facing context, the public join address must use the project identity, not the operator's surname.

### 3.2 Operator handle vs real name

- Server-side: ops list uses `MeteoricMetric` (handle), not "Merric Strough"
- In-game chat: handle, not real name
- Discord bridge (if enabled): handle, not real name
- Server logs: handles, no first/last name fields

Real-name material lives only in:
- Architecture docs (this repo, the website repo) — these are public anyway by §10 of the master CLAUDE.md
- Backup encryption metadata — not user-visible

### 3.3 Photos and screenshots

The website's CLAUDE.md §5.3 forbids face photos. This extends to the Minecraft project:

- ❌ No face photos of Merric or any player on `/minecraft`, in BlueMap, in Discord, in screenshots
- ✅ Avatar (custom illustration) acceptable — already in use on the site
- ✅ In-game screenshots acceptable provided no player skin in the screenshot resembles a real person
- ✅ Build/landscape/structure screenshots acceptable

**Screenshot review checklist** (before publishing any screenshot to the website):
- [ ] No player usernames visible in the chat overlay
- [ ] No coordinates visible (F3 debug screen, or coordinate plugins)
- [ ] No player faces in skins that resemble real people
- [ ] No external app windows visible (Discord overlay, browser tabs, etc.)
- [ ] No private chat content
- [ ] If a player is in the shot, they are wearing a generic skin or are far from camera

---

## 4. Discord integration posture

### 4.1 Default mode: event notifications only

The default DiscordSRV configuration is **server-event posting only** — joins, leaves, deaths, achievements appear as bot messages in a designated channel. **Game chat is NOT bridged to Discord by default.**

This is a deliberate child-safety choice. Bidirectional chat creates:
- A persistent, searchable record of what kids said in game
- Cross-platform identity linking (Discord username ↔ Minecraft username)
- Increased exposure if the Discord server is ever shared more widely
- A vector for kids to see content posted in Discord that wouldn't be allowed in-game

### 4.2 Upgrade path to bidirectional chat

To enable Discord ↔ Minecraft chat bridge, all of the following must be true:

1. The Discord server is private to a defined member list (no public invites)
2. Shane is an admin in the Discord server
3. Channel-level permissions restrict the bridge channel to the same member list
4. The bridge is configured to redact mentions of real names if any leak in
5. A documented decision exists in `docs/decisions/` explaining the upgrade
6. Merric and Shane have explicitly agreed

This is a Phase 3+ decision, not a Phase 0 default.

### 4.3 Discord bot permissions

The DiscordSRV bot, regardless of mode:
- ❌ Cannot ban Discord users (use Discord moderation tools instead)
- ❌ Cannot DM users
- ❌ Cannot post outside the designated bridge channel
- ✅ Can read its own channel
- ✅ Can post server events
- ✅ Can post webhook content for milestone events

### 4.4 If a future AI moderation layer is added

Per the research report's recommendation, a future "LoreBot/Warden" AI feature must be:
- Local-only inference (no third-party API for in-game content)
- Read-only by default — no ability to ban, kick, rollback, or modify whitelist
- Logged — every action visible to Shane
- Bypassable — Shane can turn it off without affecting the server

This is documented separately in a future ADR-0010 if the feature is ever pursued.

---

## 5. Moderation policy

### 5.1 Rules visible to all players

The current rules (in-game and on `/minecraft`):

1. Don't grief other people's builds. CoreProtect logs everything; rollbacks happen.
2. Be cool to Bedrock players. They're playing too.
3. No slurs, no real-world drama in chat. Discord bridge (if enabled) is family-friendly.
4. Ask before you take from someone's chest.
5. Bug or grief? Screenshot + tell Merric or Shane.

### 5.2 Escalation ladder

| Severity | Example | Response | Who decides |
|---|---|---|---|
| Minor | First-offense rude word | Verbal warning in-game (or Discord DM if it's a friend) | Merric |
| Moderate | Repeated rude language; petty grief | Temporary kick (1 hour); CoreProtect rollback | Merric, Shane informed |
| Significant | Persistent harassment; large grief; sharing real-world info | Whitelist removal; CoreProtect rollback; Shane notified before action | Shane |
| Severe | Threats, sexual content, sharing CSAM, doxxing | Immediate whitelist removal, Discord ban, server logged off if needed; report to platform if applicable | Shane only |

### 5.3 Parent override

Shane can:
- Remove any player from the whitelist at any time
- Take the server offline at any time
- Override any moderation decision Merric has made
- Edit, hide, or remove any public-facing content (website, BlueMap, Discord)
- Change this policy

These are not procedural decisions. They happen as needed. They are not negotiable in the moment.

### 5.4 Friend removal — process

When a friend needs to be removed from the whitelist:

1. **Pause** — don't act in anger; sleep on it if possible
2. **Document** — note what happened, when, what was said (screenshots if needed)
3. **Discuss with Shane** — even for moderate-tier removals
4. **Action**: `./scripts/ops.sh unwhitelist <name>`
5. **Notify** — brief, factual message to the friend explaining (Shane can write or review)
6. **Record** — log entry in a private incident log (not in this repo)

Re-adding a removed friend is a separate decision, not automatic.

### 5.5 If a player reports something serious

If a player tells Merric "someone said/did something serious":

1. **Believe them first.** Investigate, don't dismiss.
2. **Don't engage publicly** in chat about it.
3. **Tell Shane** — even if it seems small.
4. **Preserve evidence** — screenshots, log entries.
5. **Apply the escalation ladder.**

---

## 6. Public-discoverability decision

The current state of MeteoricCraft is **whitelist-only, friends-only, not publicly advertised**. This means:

- ✅ The status widget on `/minecraft` is fine — strangers seeing "MeteoricCraft is online" doesn't enable them to join
- ✅ The website link to the project is fine — same logic
- ✅ Sharing the connection address in private Discords is fine
- ❌ Posting the address publicly on social media triggers a re-evaluation
- ❌ Streaming the server publicly without anonymizing usernames triggers a re-evaluation

If the project ever broadens to public discovery:
1. Migrate the public join address to `play.meteoriccraft.com`
2. Re-review the public/private data taxonomy
3. Implement player-name redaction in any public visualization
4. Establish a contact channel for join requests (form on website)
5. Establish a moderation team (more than Merric + Shane)
6. Consider whether AI moderation is required at that scale
7. Update this policy with the new posture

This is a Phase 5+ decision, possibly "never," depending on how Merric wants the project to grow.

---

## 7. Periodic review

This policy is reviewed:

- **Quarterly** — alongside the existing identity-health and content-freshness audits scheduled in the website repo. Verify the public/private taxonomy is still being honored.
- **Before any major feature addition** — new plugins, new integrations, new public surfaces all trigger a policy re-read.
- **After any incident** — a moderation event automatically triggers review of the relevant section.
- **Annually** — full document re-read every May 1, alongside the website's annual security review.

Each review records its date and outcome in the changelog at the bottom of this file.

---

## 8. Cross-references

- `merricstrough.com/CLAUDE.md` §5 — Security standards (master)
- `merricstrough.com/CLAUDE.md` §10 — Cross-site identity & family graph
- `merric-minecraft/docs/decisions/ADR-0008` — Decision rationale for this policy
- `merric-minecraft/docs/RUNBOOK.md` — Operational change-management ladder
- `merric-minecraft/docs/PLUGIN-GOVERNANCE.md` — Approved sources, related to bot/AI access boundaries

---

## Changelog

- **v1.0** (2026-05-02) — Initial creation as part of merric-minecraft v1.1 release. Establishes baseline policy.

---

*"The default for unknown is closed."*
