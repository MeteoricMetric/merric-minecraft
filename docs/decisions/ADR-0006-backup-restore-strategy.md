# ADR-0006: Backup and restore strategy

## Status
Accepted — 2026-05-02

## Context

Minecraft world data is irreplaceable in the same way a kid's notebook of drawings is irreplaceable. Recreating "the village we built together" from scratch is not the same thing.

The server runs continuously. Backups must be:

- Atomic (consistent point-in-time snapshots, not torn writes)
- Encrypted (the world contains chat logs, player coordinates, and other PII)
- Frequent enough that data loss is bounded (RPO ≤ 24h)
- Restorable in a reasonable window (RTO ≤ 2h)
- Tested (a backup that's never restored is not a backup)
- Cheap (this is a kids' project, not an enterprise SLA)
- Off-host eventually (the workstation could die, get stolen, or be lost in a move)

## Decision

### Tool: **restic**

restic is the chosen backup tool because:
- Encrypted by default (AES-256 + Poly1305 MAC)
- Deduplication (worlds barely change day-to-day; storage cost stays low)
- Cross-platform; supports local disk, SFTP, S3, Backblaze B2, and other backends
- Single-binary, well-maintained, simple CLI
- Atomic snapshots (the snapshot itself is consistent)

Alternatives considered:
- **borg** — also excellent; restic has slightly better cloud-backend story
- **rsync + cron** — no encryption, no dedup, harder to verify integrity
- **Plugin-based backups (DriveBackupV2 etc.)** — integrate with Google Drive, but require trusting the plugin's encryption story (often weak) and operate inside the JVM with all of its access. Rejected for the trust boundary.
- **ZFS snapshots on the host filesystem** — would work, but the workstation isn't on ZFS today; adopting ZFS just for this is overkill

### Atomic snapshot mechanism: **`save-off` + `save-all flush` + restic + `save-on`**

The `scripts/backup.sh` script issues these commands via RCON before snapshotting:

1. `save-off` — server stops auto-saving the world (in-memory changes still happen)
2. `save-all flush` — flush pending writes to disk
3. Brief pause (2-3 seconds) for the flush to complete
4. `restic backup` — atomic snapshot of `data/` directory
5. `save-on` — server resumes auto-saving (regardless of whether backup succeeded)

This guarantees the snapshot represents a consistent point in time without taking the server offline.

### 3-2-1 design

| Layer | What | Where | Why |
|---|---|---|---|
| 1 | Live data | Workstation SSD | Hot, fast, in-use |
| 2 | Local snapshots | Workstation external drive (`/mnt/<backup-volume>/minecraft-restic`) | Fast restore; survives a drive failure on the primary SSD |
| 3 | Off-site snapshots | Backblaze B2 (initially deferred; added in Phase 2) | Survives workstation loss, theft, or natural disaster |

Phase 0 ships with **layer 2 only** (local external drive). Layer 3 (B2) is added in Phase 2 once the local backup process is proven over 2-3 weeks.

### Backup schedule

- **Daily** — full atomic snapshot at 3am via cron (`scripts/backup.sh`)
- **On-demand** — before any plugin update, version upgrade, or significant change (per RUNBOOK.md §4)
- **Pre-restore** — when restoring, the current state is moved aside (not deleted) before the restore overwrites it (see `scripts/restore.sh`)

### Retention

- **Daily snapshots: 7-day rolling window** — maintained by `restic forget --keep-daily 7 --prune`
- **Weekly snapshots: 4-week rolling** — added when Phase 2 ships (B2 makes longer retention cheap)
- **Monthly snapshots: 6-month rolling** — added when Phase 2 ships
- **No "forever" backups** — at some point, an old enough world isn't recoverable into the current Minecraft version anyway

### RPO and RTO

- **RPO (data loss tolerance): 24 hours** — daily snapshots; less than a day's play might be lost
- **RTO (recovery time): 2 hours** — restic restore + container restart time for a typical world

### Restore drill cadence

**Quarterly**, aligned with the website repo's existing scheduled audits (identity health check, content freshness audit, annual security review). Suggested calendar:

- 2026-08-01 (next)
- 2026-11-01
- 2027-02-01
- 2027-05-01

Drill procedure documented in RUNBOOK.md §3. Each drill records its outcome in `docs/audits/restore-drill-YYYY-MM-DD.md`.

### Encryption key handling

- Restic encryption password stored in `~/.restic-password` (file mode 0600)
- Password also recorded in Shane's password manager (1Password / Bitwarden)
- Password also written and stored offline with other recovery codes
- **Password loss = data loss** — there is no recovery without it; this is by design (security feature)

### What's backed up

- `data/world/` — primary world
- `data/world_nether/`, `data/world_the_end/` — dimensions
- `data/plugins/` — plugin jars and their config/data subdirectories
- `data/banned-players.json`, `data/banned-ips.json`, `data/whitelist.json`, `data/ops.json`
- `data/server.properties`
- `data/config/` — Paper config

### What's NOT backed up

- `data/logs/` — disposable; rotated by Paper anyway
- `data/cache/` — disposable; regenerated automatically
- `data/crash-reports/` — kept locally for debugging, not worth backing up
- `data/libraries/` — Paper downloads these; regenerated on container restart
- The Docker container itself or its image layers — handled by `docker pull`

## Alternatives considered and rejected

- **Realms-style "managed backups"** — would require switching to Realms; out of scope
- **Plugin-based world saves to Google Drive** — trust boundary issues, plugin reliability, weaker encryption
- **Manual `tar` script** — no encryption, no dedup, easy to forget
- **Snapshot the entire VM** — workstation isn't a VM
- **Continuous replication via `inotify` + rsync** — overkill, write-amplification on the SSD

## Consequences

### Good
- Encryption by default — even if the backup drive is stolen or B2 is breached, contents are unreadable
- Deduplication keeps storage cheap (typical Minecraft world: 200MB → 200MB initial, then ~50MB/day delta)
- restic restore is straightforward; we have a tested script
- 3-2-1 satisfies the standard data-protection design
- Restore drills catch issues before they matter
- Architecture supports easy upgrade to off-site (B2) without changing scripts

### Bad / accepted tradeoffs
- Phase 0 has only a single backup location (local) — accepted because primary SSD failure is rarer than human-error data loss; B2 added in Phase 2
- Encryption key management is on Shane — if the password is lost, the backups are unrecoverable
- Daily cadence means up to 24h data loss in worst case (consciously accepted; finer cadence trades off cost for diminishing returns)

### Things to revisit
- After 3 successful restore drills: increase confidence and consider longer retention
- After Phase 2 (B2 added): re-run a full restore drill from B2, not just local
- If world size grows beyond 5GB: revisit retention and possibly the backup mechanism

## References

- restic documentation: https://restic.readthedocs.io
- 3-2-1 backup principle: https://www.cisa.gov/sites/default/files/publications/data_backup_options.pdf
- Backblaze B2 pricing: https://www.backblaze.com/cloud-storage/pricing
- Minecraft `save-off` / `save-all flush` semantics: https://minecraft.wiki/w/Commands/save-off

---

*Decision recorded by: Shane Strough, May 2026*
