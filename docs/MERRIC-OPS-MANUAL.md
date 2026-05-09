# Merric's Operations Manual

> Your manual. Built for you, the owner. Keep it open in a browser tab while you play — the commands are copy-paste ready.

## What this server is

MeteoricCraft is your public economy-survival server with PvP enabled and full Java/Bedrock cross-play. It runs on the workstation in your house through a playit.gg tunnel, so anyone with the address can join — but you and Shane are the only operators, and you decide what happens on it.

## Daily Quick-Reference (the 10 commands you'll use most)

| Command | What it does |
|---|---|
| `/spawn` | Teleports you to spawn. Always works, no cooldown for you. |
| `/rtp` | Random teleport into the wild — good for finding fresh terrain. |
| `/sethome <name>` | Saves your current spot as a home you can return to. |
| `/home <name>` | Teleports back to a saved home. `/home` alone goes to your default. |
| `/tpa <name>` | Asks a player if you can teleport to them. They type `/tpaccept`. |
| `/msg <name> <text>` | Private message. Replies with `/r <text>`. |
| `/balance` | Shows your in-game money. `/bal` works too. |
| `/kit welcome` | Claims the welcome kit. New players use this on first join. |
| `/dailyrewards` | Opens the daily login reward menu — claim once per day. |
| `/crates` | Shows the crate menu. Lists keys you're holding and crate locations. |

## When a friend wants to join

1. Ask which platform they're on. **Java** players need their Minecraft username (case-sensitive). **Bedrock** players need their Xbox gamertag — that's their account name, not their character name.
2. Send them the connect address:
   - **Java:** `mc.merricstrough.com` (no port — the client figures it out)
   - **Bedrock:** server `mc.merricstrough.com`, port `47785`
3. They connect. That's it — no whitelist to add them to. Per ADR-0010 the server is publicly joinable, and Floodgate handles the Bedrock-side login automatically (their name will show up with a `.` prefix, like `.MerricsBuddy`).

If they grief once they're in, you don't have to ban them on the spot — CoreProtect lets you roll back what they broke. See **When something goes wrong** below.

## Admin powers (you have all of these)

You're op. These all work for you:

- `/heal` — refills your hearts
- `/feed` — refills your hunger bar
- `/fly` — toggles flight on or off
- `/gm 1` / `/gm 0` — switches you to creative / back to survival
- `/god` — toggles invincibility (great for testing bosses)
- `/i <item>` — gives you an item (e.g. `/i diamond_sword`)
- `/give @s <item> <count>` — vanilla version, takes a count
- `/tp <player>` — teleport directly to a player
- `/setwarp <name>` / `/warp <name>` — set or jump to a public warp
- `/op <name>` / `/deop <name>` — grant or remove operator status. **Don't op friends casually** — op = full power. Use warps and game ranks instead.
- `/kick <name> [reason]` — boots a player. They can rejoin.
- `/ban <name> [reason]` / `/pardon <name>` — permanent ban / unban.

`/ban` is the nuclear option. **Kick first** for almost everything. Only ban for repeat offenders or someone who shows up specifically to wreck things. Most "bad behavior" is fixable with a kick and a rollback.

## Spawning custom bosses

You have three custom bosses, all created with MythicMobs. Spawn them for testing or for a planned event with friends:

```
/mm spawn CosmicKnight 1     # easy fight, drops a Common Key
/mm spawn MagmaSentinel 1    # medium fight, drops a Rare Key
/mm spawn VoidReaver 1       # boss event, drops Legendary Key + netherite + sometimes an enchanted item
```

CosmicKnight and MagmaSentinel also spawn naturally:
- 3% of nighttime surface skeletons turn into Cosmic Knights
- 10% of nether blazes turn into Magma Sentinels

Void Reaver only spawns when you summon it. That's intentional — it's the showpiece fight.

If a boss feels too easy or too brutal, that's a 🟡: tell Shane (or me) and we'll re-tune the config.

## Giving crate keys to a friend

The pattern is:

```
/crates give physical <Tier> <amount> <player>
```

Tier is capitalized (`Common`, `Rare`, `Legendary`); player name is lowercase. Examples:

```
/crates give physical Common 1 cooldude42
/crates give physical Rare 3 cooldude42
/crates give physical Legendary 1 cooldude42
```

The key shows up in their inventory. They walk to the **south edge of spawn**, find the chest matching the tier, hold the key, and right-click it. Crate animation plays, loot drops. If a chest "isn't working," 9 times out of 10 they're holding the wrong tier key.

## When something goes wrong

### 🟢 Safe to handle yourself

- **Player griefed something.** Roll back what they did:
  ```
  /co rollback u:<name> t:1d r:50
  ```
  That's "everything this user did in the last day, within 50 blocks." Adjust `t:` (time) and `r:` (radius) to taste — `t:1h` for last hour, `r:200` for a wider blast. CoreProtect undoes block changes, container access, and entity kills.
- **Someone's being mean in chat.** Kick them:
  ```
  /kick <name> chat conduct
  ```
  They can rejoin if they chill out. If they don't, kick again. Pattern of three? Talk to Shane about a temp ban.
- **Server feels laggy.** Run a profiler:
  ```
  /spark profiler start --timeout 60
  /spark profiler stop
  ```
  Spark posts a link showing what's eating CPU. Send the link to Shane if you can't tell what's wrong from the report.

### 🟡 Get Shane

- Friends saying "can't connect" when the server is up for you (probably the playit tunnel)
- Server crashed and didn't auto-restart
- A mob is doing impossible damage, or a boss feels broken in a way `/mm` configs can't fix
- You want to add a new plugin (PLUGIN-GOVERNANCE.md is the process)

### 🔴 Shane only

- Restoring from a backup — see RUNBOOK.md §3.3
- Major plugin updates (Paper version bumps, big plugin overhauls)
- Anything DNS or playit related
- Anything that needs `sudo` on the host

## Backups

A restic backup runs every day at 3am on the host. You don't have to do anything to make backups happen — they just happen.

Listing snapshots needs SSH access to the host:

```
~/bin/restic snapshots
```

You'd ask Shane to run that. **Restoring** is 🔴 — Shane only, always. Restores can lose recent progress if done wrong, so it's a two-person job by policy.

## The Secret Cave

There's a hidden cave at **(220, 25, 220)** underground. Inside right now: an enchanting table, surrounded by max-level bookshelves, plus treasure chests and soul campfires for the blue glow.

The **entry mechanism is your call.** Trapdoor under a painting? Lever behind a waterfall? Riddle on a sign that opens a piston door when you hit the right note block? Decide what you want — tell Shane or tell me, and we'll build it.

## When to ask Shane

- Anything marked 🔴 above
- Anything that costs money (hosting tier changes, paid plugins)
- Anything that involves promoting the server outside your friend group (Reddit posts, Discord lists, YouTube)
- **Any** chat report involving creepy DMs, slurs, or someone asking for real-world info about you or anyone else. This is non-negotiable — the policy is in `docs/CHILD-SAFETY-PRIVACY.md` and it exists to keep you safe. No judgement, no questions, just forward it.

## Cheat sheet poster (for your wall, optional)

```
COMMON:  /spawn   /rtp   /sethome   /home   /balance
ADMIN:   /heal    /feed  /fly       /tp <player>
POWER:   /mm spawn <boss> 1     /crates give physical <Tier> 1 <player>
```

---

You're the operator, Merric. The server runs because you run it. Shane's here when you need him, but the day-to-day — the players, the events, the bosses, the crates, the cave — that's yours.

Have fun out there.
