#!/usr/bin/env bash
# scripts/ops.sh — One-stop ops shell for MeteoricCraft
#
# Usage:  ./scripts/ops.sh <command>
#
# Designed so Merric only has to remember ONE script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

CMD="${1:-help}"

case "$CMD" in
  start)
    echo "Starting MeteoricCraft..."
    docker compose up -d
    echo "Done. Watch logs with: ./scripts/ops.sh logs"
    ;;

  stop)
    echo "Stopping MeteoricCraft..."
    docker compose down
    ;;

  restart)
    docker compose restart mc
    ;;

  status)
    docker compose ps
    echo ""
    echo "Latest health:"
    docker inspect --format='{{.State.Health.Status}}' meteoriccraft 2>/dev/null || echo "no health data"
    ;;

  logs)
    docker compose logs -f --tail 100 mc
    ;;

  console)
    # Drop into the server's interactive console via rcon
    docker compose exec mc rcon-cli
    ;;

  whitelist)
    PLAYER="${2:-}"
    if [[ -z "$PLAYER" ]]; then
      echo "Current whitelist:"
      docker compose exec mc rcon-cli whitelist list
    else
      echo "Adding $PLAYER to whitelist..."
      docker compose exec mc rcon-cli whitelist add "$PLAYER"
    fi
    ;;

  unwhitelist)
    PLAYER="${2:?Usage: ops.sh unwhitelist <player>}"
    docker compose exec mc rcon-cli whitelist remove "$PLAYER"
    ;;

  online)
    docker compose exec mc rcon-cli list
    ;;

  backup)
    "$SCRIPT_DIR/backup.sh"
    ;;

  restore)
    "$SCRIPT_DIR/restore.sh"
    ;;

  update)
    echo "Pulling latest images..."
    docker compose pull
    echo "Recreating containers..."
    docker compose up -d
    ;;

  shell)
    docker compose exec mc bash
    ;;

  help|*)
    cat <<EOF
MeteoricCraft Ops

Usage: ./scripts/ops.sh <command>

Server lifecycle:
  start            Start the server
  stop             Stop the server
  restart          Restart just the Minecraft container
  status           Show running services and health

Watching:
  logs             Tail the server log (Ctrl+C to exit)
  online           Show who's currently playing
  console          Drop into the in-game admin console (rcon)

Player management:
  whitelist        Show current whitelist
  whitelist <name> Add a player to the whitelist
  unwhitelist <n>  Remove a player from the whitelist

Maintenance:
  backup           Run a manual backup right now
  restore          Restore from a previous backup (interactive)
  update           Pull latest images and recreate containers
  shell            Drop into a shell inside the container (advanced)

EOF
    ;;
esac
