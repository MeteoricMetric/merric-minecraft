#!/usr/bin/env bash
# scripts/restore.sh — Interactive restore of a Minecraft world from restic backup
#
# Usage:  ./scripts/restore.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

set -a
source .env
set +a

: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY must be set in .env}"
: "${RESTIC_PASSWORD_FILE:?RESTIC_PASSWORD_FILE must be set in .env}"

echo "═══════════════════════════════════════════════════════════"
echo "  MeteoricCraft — World Restore"
echo "═══════════════════════════════════════════════════════════"
echo ""

# List recent snapshots
echo "Available snapshots:"
restic snapshots \
  --repo "$RESTIC_REPOSITORY" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  --compact

echo ""
read -rp "Enter snapshot ID to restore (or 'latest'): " SNAPSHOT_ID

if [[ -z "$SNAPSHOT_ID" ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "⚠️  WARNING ⚠️"
echo "This will REPLACE the current world data with snapshot $SNAPSHOT_ID."
echo "The current ./data directory will be moved to ./data.before-restore.<timestamp>"
echo ""
read -rp "Type RESTORE to continue: " CONFIRM

if [[ "$CONFIRM" != "RESTORE" ]]; then
  echo "Aborted."
  exit 1
fi

# Stop the server
echo ""
echo "Stopping server..."
docker compose stop mc || true

# Move current data aside
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
if [[ -d "./data" ]]; then
  echo "Moving current ./data to ./data.before-restore.${TIMESTAMP}"
  mv ./data "./data.before-restore.${TIMESTAMP}"
fi

# Restore
echo "Restoring snapshot..."
restic restore \
  --repo "$RESTIC_REPOSITORY" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  --target "." \
  "$SNAPSHOT_ID"

# Restart
echo "Starting server..."
docker compose up -d mc

echo ""
echo "✅ Restore complete. Server starting up."
echo "Watch: docker compose logs -f mc"
echo ""
echo "If something looks wrong, your previous world is at:"
echo "  ./data.before-restore.${TIMESTAMP}"
echo "Delete that directory only after you've confirmed the restore worked."
