# MeteoricCraft — Player Guide

## What this is

MeteoricCraft is a friend-and-friend-of-friend Minecraft server run by Merric (13) and his dad. It's cross-play, which means Java *and* Bedrock both work — so your Switch, phone, Xbox, PlayStation, Windows 10/11, Mac, Linux box, or PC can all connect to the same world. Same chunks. Same chat. Same chaos.

It's public-economy survival with PvP enabled outside spawn. We've got custom bosses, three tiers of crates, daily login rewards, a real in-game economy with player auctions, land-claim protection so people can't grief your base, and a live web map of the world. Build something cool. Fight something scary. Sell something for a wildly inflated price. Have fun.

## How to connect

### Java Edition (PC / Mac / Linux)

| Field | Value |
|---|---|
| **Address** | `mc.merricstrough.com` |
| **Port** | not needed (SRV record handles it) |

Open Minecraft → Multiplayer → Direct Connect → paste the address → Join Server.

### Bedrock Edition (Switch / phone / Xbox / PlayStation / Win10/11)

| Field | Value |
|---|---|
| **Address** | `mc.merricstrough.com` |
| **Port** | `47785` |

Open Minecraft → Servers tab → Add Server → fill in the address and port → Save → connect.

**Console caveat:** Switch, Xbox, and PlayStation block custom server addresses by default. There's a one-time DNS workaround called **BedrockConnect** that fixes this (see footnote at the end).

## What you'll see when you join

Spawn is a **41×41 floating platform** with a glowing meteor pillar at the center — you can see it from a long way off. Four corner towers mark the boundary. Five floating signs point you to **SHOP**, **CRATES**, **WILDERNESS**, **DAILY REWARDS**, and a center banner with the server name. Three crate chests sit on emerald, diamond, and gold pedestals (Common, Rare, Legendary). Three admin-shop chests handle buying and selling. At the east edge, there's a pressure plate that randomly teleports you into the wilderness. A beacon pulses Speed I across the whole platform so you don't trudge.

**Spawn is a safe zone.** No PvP, no building, no breaking. Step off the platform and you're fair game.

## What you can do

- **Survive + build** — full vanilla Minecraft progression. Mine, fight, build a base. PvP is enabled the moment you leave spawn.
- **Claim your base** — type `/claim` while holding a golden shovel to lock down chunks (powered by GriefPrevention). New players get **100 starter blocks**, plus **+100/hr** of playtime, capped at **5000 blocks**.
- **Earn money** — kill mobs, sell loot to admin shops, list items on the player auction house with `/ah`, or open crates and gamble on glory.
- **Open crates** — three tiers: **Common**, **Rare**, **Legendary**. Keys drop from daily rewards, voting, and (rarely) custom bosses.
- **Level up skills** — AuraSkills auto-tracks **11 skills** (mining, fighting, archery, fishing, foraging, and more). Just play. Watch the XP bar at the top of your screen.
- **Duel friends** — `/duels` opens a 1v1 PvP arena with balanced kits. No gear-loss drama.
- **Daily rewards** — `/dailyrewards` claims a **7-day streak**. Day 1 is small. Day 7 is a Legendary Key. Miss a day, the streak resets — show up.
- **Random teleport** — `/rtp` drops you 100–5000 blocks from origin into open wilderness ready to claim. Or just step on the pressure plate at the east edge of spawn.

## Custom bosses

Three custom bosses, each with their own abilities and named loot:

- **Cosmic Knight** (1500 HP) — spawns at night on the surface. Fires explosive cosmic blasts. Drops a **Common Crate Key** and iron.
- **Magma Sentinel** (5000 HP) — spawns in nether biomes. Fire-immune, splashes lava in an AOE around itself. Drops a **Rare Crate Key**, magma blocks, and blaze rods.
- **Void Reaver** (12000 HP) — admin-summoned event boss. Lifesteals, teleports to its target, summons zombie adds. Drops a **Legendary Crate Key**, netherite, and a chance at enchanted gear. Don't fight it alone.

## Rules (short — please read)

1. **Be cool.** No slurs, no bullying, no creepy DMs. Permanent ban, no warning.
2. **No griefing claimed bases.** Ask before taking from chests that aren't yours.
3. **No cheats, no x-ray, no exploits.** Permanent ban.
4. **PvP is part of the server — but not at spawn.** Outside spawn is the wilderness. Bring gear.
5. **Treat Bedrock players like Java players** (and vice versa). They're playing too.

## A note for parents

This server is run by a **13-year-old (Merric)** with adult oversight by his dad (Shane). A few things worth knowing before you let your kid join:

- **Moderation in place of a whitelist.** Rather than a strict invite-only list, MeteoricCraft uses compensating controls: **CoreProtect** logs every block change and supports full rollback of griefing; **anti-combat-log** prevents quitting mid-fight to escape consequences; the spawn safe-zone prevents new-player ambushes; and Merric and Shane are both server admins with full ban and rollback authority.
- **Privacy.** No personally identifying information is required to join — only a Minecraft username. The server doesn't show real names, ages, locations, or anything beyond in-game username. The status widget at `merricstrough.com/minecraft` shows the online **player count only** by default — no names visible to the public.
- **Discord.** There is **no chat bridge to Discord** at this time, by design. Server chat stays in the server. If we ever change this, it'll be announced and parents will be told first.
- **Concerns.** If you see anything concerning — chat behavior, a player being mistreated, anything that doesn't sit right — contact Shane via the channel Merric shared with you. Reports get a real human response.

## Server status & uptime expectations

MeteoricCraft is hosted on a home workstation, not a datacenter. Most days the server is online 24/7. Sometimes it goes down for a few minutes for maintenance, plugin updates, or because the workstation is being rebooted for the other things it runs. We aim for high availability but we don't promise it.

**Live status:** https://merricstrough.com/minecraft — the web widget on that page shows online / offline / current player count in real time. Check it before you panic.

## Connect addresses, summarized

| Edition | Address | Port |
|---|---|---|
| **Java** | `mc.merricstrough.com` | (none — SRV) |
| **Bedrock** | `mc.merricstrough.com` | `47785` |

See you in the wilderness. Build something weird, fight something terrifying, and have a great time.

---

*Footnote — BedrockConnect for consoles:* Nintendo Switch, Xbox, and PlayStation block custom server addresses by default, but **BedrockConnect** is a free, well-known community workaround that lets you set your console's DNS to a public BedrockConnect server, after which "Featured Servers" becomes a list you can add `mc.merricstrough.com:47785` to. Search "BedrockConnect setup" plus your console name for current step-by-step instructions — the DNS addresses change occasionally, so the latest guide beats anything we'd hardcode here.
