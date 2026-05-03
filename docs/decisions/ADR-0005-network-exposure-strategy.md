# ADR-0005: Network exposure strategy

## Status
Accepted — 2026-05-02 (supersedes the network section of ADR-0004 with more detail)

## Context

MeteoricCraft must accept connections from Java and Bedrock clients on the internet, hide Shane's home residential IP, scale gracefully if friend count grows, survive Shane's eventual move from FL to CO, and not commit the project to a single vendor.

The decision space included:

1. **Direct port forwarding** on Shane's home router
2. **Tailscale-only** access for friends
3. **playit.gg** TCP/UDP relay tunnel
4. **Cloudflare Tunnel** (cloudflared) for Minecraft traffic
5. **Cloudflare Spectrum** (TCP/UDP at Cloudflare's edge)
6. **Self-hosted VPS** with WireGuard back to the home host
7. **Dedicated managed Minecraft host** (Shockbyte, Bisect, etc.)

## Decision

### Phase 0 (now → ~3 months): **playit.gg**

- Free tier or $3/mo Premium (advertised pricing, verified May 2026)
- TCP+UDP relay; supports both Java (TCP) and Bedrock (UDP) natively
- Hides Shane's home IP behind playit's anycast network
- Setup is ~5 minutes; agent runs in the same Docker compose stack as the server
- No router configuration required

### Phase 1+ (when triggered): **VPS + WireGuard**

When growth or specific events trigger the upgrade, migrate the public edge to a $5–$10/month VPS, with WireGuard as the back-haul tunnel from the VPS to Shane's home host. The home host keeps doing the heavy lifting; the VPS owns the public IP, firewall, reverse proxy, BlueMap publishing, and HTTPS APIs.

### Phase 2+ (legendary tier, optional): **Multi-region edge**

Replicate the VPS pattern to a second region for HA. Probably never needed for a friend server, but the architecture supports it.

## Trigger events for migration

The system stays on Phase 0 (playit.gg) unless one of these triggers:

| Trigger | Consequence |
|---|---|
| playit reliability drops below 95% over a month | Move to VPS |
| Concurrent player count regularly exceeds 10 | Move to VPS (better latency control) |
| Need for custom DNS / SSL termination beyond what playit offers | Move to VPS |
| Need for traffic logging beyond what playit exposes | Move to VPS |
| Shane physically moves and wants infrastructure independent of new home network | Move to VPS |
| MeteoricCraft becomes publicly discoverable per CHILD-SAFETY-PRIVACY.md §6 | Move to VPS (mandatory — better moderation/abuse logging) |
| Total monthly playit cost (free tier + premium add-ons) exceeds $15 | Reconsider — VPS may be cheaper |

## Alternatives considered and rejected

### Direct port forwarding — REJECTED
- Exposes Shane's home IP. Single biggest doxxing risk for a kids' server.
- ISP ToS gray area for residential connections
- Home router becomes a security-critical edge device with no isolation
- Pivot risk if the Minecraft server is ever exploited (Log4Shell-class events recur)
- CISA and FTC home-network guidance do not contemplate hosted services on residential connections
- Acceptable only as an emergency fallback for testing on the LAN

### Tailscale-only — REJECTED for public ingress, ACCEPTED for admin overlay
- Friends would need to install Tailscale and be added to a tailnet — high friction for kids
- Console players (Xbox, Switch, PS) cannot run Tailscale — would exclude this use case
- Excellent fit for **internal admin access** to the workstation (already in use), not for public game ingress

### Cloudflare Tunnel for Minecraft — REJECTED
- Cloudflare's documentation places public TCP/UDP application delivery under **Spectrum**, not Tunnel
- Tunnel/public-hostname patterns center on HTTP(S); arbitrary TCP via Tunnel uses Cloudflare Access with client-side tooling (cloudflared) on the player side
- Bedrock requires public UDP; Cloudflare Tunnel does not natively expose UDP applications publicly without Spectrum
- Forcing every player to install cloudflared as a Tunnel client is unacceptable friction for kids
- Materially the wrong tool. Cloudflare is excellent for HTTP control plane (status worker, future APIs, dashboards) — see ADR-0001 (in the website repo) and the Worker pattern already in use

### Cloudflare Spectrum — REJECTED for now
- Spectrum supports Minecraft (documented), TCP+UDP at the edge, DDoS absorption
- Public self-serve pricing is not transparent for hobbyist scale; treated as enterprise sales-led
- Overkill for a friend server; reconsider only if MeteoricCraft becomes a serious public service
- Architecturally interesting; financially impractical at our scale

### VPS + WireGuard — DEFERRED, NOT REJECTED
- The right Phase 1 target. Reasons not to do it on day one:
  - Adds $60–$120/year to an otherwise free stack
  - Adds operational complexity (one more host to maintain)
  - playit.gg satisfies all current functional requirements
  - The architecture stays portable to this option (no lock-in to playit)
- We will do this when triggered by §"Trigger events" above

### Dedicated managed Minecraft host — REJECTED
- $7–$28/month for a useful tier
- Forfeits all the learning value of self-hosting
- The whole point is Merric learning real infrastructure
- Easy fallback if life circumstances force it later

## Consequences

### Good
- Phase 0 cost is zero or near-zero
- Shane's home IP stays private behind playit's anycast network
- Bedrock UDP works natively (a deal-breaker for several alternatives)
- DDoS absorbed by playit's edge, not Shane's residential connection
- Migration path to Phase 1 is clean — same Docker stack, swap the tunnel for a WireGuard config
- Architecture decisions are reversible and scaled to current actual need

### Bad / accepted tradeoffs
- +30–60ms added latency through playit's relay (imperceptible for survival, slight in PvP)
- Single point of failure: playit outage = server unreachable (mitigated: friend server, not life-critical)
- Trusting playit with traffic metadata (mitigated: 2FA on account, agent in its own container, no privileged access)
- Free tier uses shared anycast IP (cosmetic; can upgrade for $3/mo Premium if reserved IP is needed)

### Things to revisit
- Quarterly: review playit reliability (uptime as observed by us, not their public status page)
- When migrating: write ADR-0005a documenting the actual VPS migration with the chosen provider, region, and config
- If broadening to public discovery: this ADR is REQUIRED to be revisited and likely superseded

## References

- Cloudflare Tunnel docs (HTTP focus): https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Cloudflare Spectrum (Minecraft mention): https://developers.cloudflare.com/spectrum/
- playit.gg documentation: https://docs.playit.gg/
- WireGuard quickstart: https://www.wireguard.com/quickstart/
- CISA home network security: https://www.cisa.gov/securing-home-network
- Geyser supported Bedrock UDP setup: https://geysermc.org/wiki/geyser/setup/

---

*Decision recorded by: Shane Strough, with research input from external research report (May 2026)*
