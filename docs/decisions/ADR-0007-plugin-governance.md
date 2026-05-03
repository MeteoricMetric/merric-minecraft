# ADR-0007: Plugin governance

## Status
Accepted — 2026-05-02

## Context

Plugins on a Minecraft server are not "extras" — they are JVM-loaded code with full access to the world, the network, and the host filesystem. A bad or compromised plugin can leak data, grief the world, or take down the server. The plugin ecosystem is also messy: many plugins are distributed via forum threads, Discord servers, and unmaintained GitHub forks.

Without a governance policy, plugin sprawl is a near-certainty: someone finds a "cool" plugin, drops it in to try it, never removes it, and three months later nobody remembers what it does. This is unacceptable for a system that's intended to be operated by a 13-year-old and to remain stable for years.

## Decision

Treat plugins as production dependencies, with the same rigor used for application code dependencies elsewhere in the project.

The full policy lives in [`docs/PLUGIN-GOVERNANCE.md`](../PLUGIN-GOVERNANCE.md). Summary of the decision:

1. **Approved sources only** — Modrinth, PaperMC Hangar, SpigotMC, and official GitHub release pages of well-known projects. No forum jars, no Discord drops, no random forks.
2. **Pinned versions for security-critical plugins** — Geyser, Floodgate, ViaVersion, ViaBackwards, DiscordSRV. Mature plugins (LuckPerms, EssentialsX, CoreProtect, WorldEdit, WorldGuard) may track latest minor.
3. **A plugin manifest** — the v1.1 manifest is in PLUGIN-GOVERNANCE.md §3, with each plugin's source, pin policy, and purpose.
4. **A formal install/update/remove process** — documented in §4-6 of PLUGIN-GOVERNANCE.md, including pre-change backups and rollback procedures.
5. **Permission boundaries via LuckPerms** — clear group structure (`default`, `trusted`, `builder`, `admin`); permissions explicit, not implicit.
6. **Quarterly permission audits** — alongside the website repo's existing scheduled identity-health check.
7. **Secret handling** — plugin secrets in `.env` or in gitignored config files only; never committed.

## Alternatives considered and rejected

- **No policy, install whatever** — predictable bit-rot, security risk, kid-operated systems need stable defaults
- **Strict pinning of every plugin** — overkill for stable plugins like LuckPerms; would slow down legitimate maintenance
- **Heavy "anti-cheat" plugins** — high false-positive rate, often more disruptive than helpful for a whitelist-only friend server
- **Outsource governance to a curated modpack** — would change the entire architecture; not the right tool for a Paper plugin server

## Consequences

### Good
- Predictable plugin set
- Easy to onboard a future operator (Merric at 16, anyone helping)
- Security boundary is explicit
- Updates are deliberate, not surprise
- Plugin manifest is the single source of truth — matches what's running

### Bad / accepted tradeoffs
- Process overhead for adding a new plugin (read docs, update manifest, commit) — accepted because the alternative is plugin sprawl
- Some "fun" plugins won't pass the source review — accepted; we can wait for them to mature

## References

- Full policy: `docs/PLUGIN-GOVERNANCE.md`
- Operational process: `docs/RUNBOOK.md` §1 (change-management ladder)

---

*Decision recorded by: Shane Strough, May 2026*
