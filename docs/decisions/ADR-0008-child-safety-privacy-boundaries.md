# ADR-0008: Child-safety and privacy boundaries

## Status
Accepted — 2026-05-02

## Context

MeteoricCraft is operated by a minor and is publicly visible (via the status widget on `merricstrough.com/minecraft`). The system has multiple surfaces (game server, website, Cloudflare Worker, future BlueMap, future Discord bridge), each of which could leak identifying or sensitive information about Merric, his friends, or the family.

Default behavior in Minecraft tooling is to expose more, not less:
- Server List Ping protocol returns `players.sample` — usernames of currently-online players
- BlueMap can show live player markers with usernames and coordinates
- DiscordSRV by default bridges all in-game chat to Discord
- Server console output contains IPs, UUIDs, and chat history
- Plugin defaults frequently expose more than is wise for a minor's server

The website's master CLAUDE.md already establishes strong privacy rules (§5.3, §10) for Merric's identity. This ADR extends that framework to the Minecraft system.

The risk surface is real: kids fight, friend groups change, and anything publicly exposed about a minor can be screenshot and shared in ways that don't age well.

## Decision

The full policy lives in [`docs/CHILD-SAFETY-PRIVACY.md`](../CHILD-SAFETY-PRIVACY.md). Decision summary:

1. **Default-closed posture** — when an exposure decision is unclear, the answer is don't expose. Add later, never roll back.
2. **Explicit public/private data taxonomy** — documented in CHILD-SAFETY-PRIVACY.md §2. Public: counts, version, MOTD, server identity. Private: usernames, IPs, chat, coordinates, backup paths, dashboards.
3. **`players.sample` filtered by default** — the Worker returns it (because the protocol exposes it) but the frontend hides it. Override requires explicit policy update.
4. **Identity boundary on hostnames** — `mc.merricstrough.com` is acceptable for the current whitelist-only state. If the server ever broadens to public discovery, the public join address moves to `play.meteoriccraft.com` (using the project identity rather than the operator's surname).
5. **Photo/screenshot policy** — no face photos; screenshot review checklist for anything published.
6. **Discord bridge is event-notify-only by default** — full chat bridging is a Phase 3+ deliberate decision with documented preconditions (per CHILD-SAFETY-PRIVACY.md §4.2).
7. **Moderation escalation ladder** — four severity tiers, with Shane retaining final authority on Severity 3+ events.
8. **Parent override is unconditional** — Shane can remove content, ban users, take the server offline, or change policy at any time, with no procedural delay.
9. **Periodic review** — quarterly aligned with the website's identity-health audit; before any new public surface; after any incident; annually on May 1.

## Alternatives considered and rejected

- **No formal policy** — relying on "we'll figure it out" — rejected; minor's safety requires explicit, written boundaries before incidents force the conversation
- **Full public posture** (everything visible by default) — rejected; the trade-off favors privacy heavily for a minor's server
- **Lock everything down to private mesh** (Tailscale-only) — rejected; would prevent Bedrock console friends from joining and removes the legitimate public-facing site benefits
- **Anonymous server identity** (no link between the Minecraft server and merricstrough.com) — rejected; the cross-site identity per master CLAUDE.md §10 is intentional and valuable. We accept the visible link and instead control what's exposed.

## Consequences

### Good
- Decisions about exposure are made deliberately, in advance, not reactively
- A future operator (Merric at 16) inherits a clear framework
- The Cloudflare Worker, the BlueMap config, the Discord setup, and any future AI feature all reference one source of truth
- Moderation has documented escalation; nothing is improvised when something happens
- The "if we ever go public" decision has a pre-defined process

### Bad / accepted tradeoffs
- The public status widget shows less than it could — count, but not names — accepted
- Discord bridge is initially less feature-rich (event notifications only) — accepted; upgrade path exists
- Some decisions Merric might want (e.g., posting builds publicly with friend names) require Shane's review — accepted; that's the point

## Things to revisit

- After any incident: re-read the relevant section
- Quarterly: verify the public/private taxonomy is being honored across all surfaces
- Before adding any new public surface (BlueMap public release, public Discord, Twitch overlay, etc.)
- If MeteoricCraft is ever considered for public discoverability: this ADR is REQUIRED to be revisited and likely superseded with a substantially revised version

## References

- Full policy: `docs/CHILD-SAFETY-PRIVACY.md`
- Master CLAUDE.md (`merricstrough.com`): §5 Security, §10 Cross-site identity
- Operational implications: `docs/RUNBOOK.md` (change-management ladder, incident response)

---

*Decision recorded by: Shane Strough, May 2026*

*"The default for unknown is closed."*
