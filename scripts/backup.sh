#!/usr/bin/env bash
# scripts/backup.sh — Atomic Minecraft world backup via restic
#
# Strategy:
#   1. Tell the server "stop saving for a moment" (rcon save-off + save-all)
#   2. Snapshot the world directory with restic
#   3. Tell the server "ok, save normally again" (rcon save-on)
#   4. Prune old snapshots beyond retention window
#
# Usage:  ./scripts/backup.sh
# Cron:   0 3 * * * /home/$USER/merric-minecraft/scripts/backup.sh

set -euo pipefail

# ── Load environment ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

if [[ ! -f .env ]]; then
  echo "FATAL: .env not found in $REPO_DIR" >&2
  exit 1
fi

set -a
source .env
set +a

# ── Sanity checks ───────────────────────────────────────────────────────────
: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY must be set in .env}"
: "${RESTIC_PASSWORD_FILE:?RESTIC_PASSWORD_FILE must be set in .env}"
: "${BACKUP_RETENTION_DAYS:=7}"

if ! command -v restic >/dev/null 2>&1; then
  echo "FATAL: restic not installed. sudo apt install restic" >&2
  exit 1
fi

if ! docker compose ps mc --format json | grep -q '"State":"running"'; then
  echo "WARN: mc container not running — backing up cold data only"
  RCON_AVAILABLE=false
else
  RCON_AVAILABLE=true
fi

# ── Helpers ─────────────────────────────────────────────────────────────────
log() { echo "[$(date -Iseconds)] $*"; }

rcon() {
  docker compose exec -T mc rcon-cli "$@" >/dev/null 2>&1 || true
}

# ── Pause world saves to get a consistent snapshot ──────────────────────────
if [[ "$RCON_AVAILABLE" == true ]]; then
  log "pausing world saves..."
  rcon save-off
  rcon save-all flush
  sleep 3
fi

# ── Snapshot ────────────────────────────────────────────────────────────────
log "starting restic snapshot..."
restic backup \
  --repo "$RESTIC_REPOSITORY" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  --tag "auto-daily" \
  --tag "host-$(hostname)" \
  --exclude "*.log" \
  --exclude "logs/" \
  --exclude "cache/" \
  --exclude "crash-reports/" \
  ./data

SNAPSHOT_RESULT=$?

# ── Resume world saves immediately, even if backup failed ───────────────────
if [[ "$RCON_AVAILABLE" == true ]]; then
  log "resuming world saves..."
  rcon save-on
fi

if [[ $SNAPSHOT_RESULT -ne 0 ]]; then
  log "FAIL: restic snapshot returned $SNAPSHOT_RESULT"
  exit $SNAPSHOT_RESULT
fi

# ── Prune ───────────────────────────────────────────────────────────────────
log "pruning snapshots older than ${BACKUP_RETENTION_DAYS} days..."
restic forget \
  --repo "$RESTIC_REPOSITORY" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  --tag "auto-daily" \
  --keep-daily "$BACKUP_RETENTION_DAYS" \
  --prune

# ── Summary ─────────────────────────────────────────────────────────────────
log "backup complete. current snapshots:"
restic snapshots \
  --repo "$RESTIC_REPOSITORY" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  --tag "auto-daily" \
  --compact

log "done."
