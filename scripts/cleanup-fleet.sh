#!/usr/bin/env bash
# ==============================================================================
# Docker Production Fleet Automated Cleanup
# Safe pruning preserving persistent state and volumes
# ==============================================================================
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[*] Running in DRY-RUN mode. No assets will be deleted."
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker CLI not found."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Docker daemon. Is Docker running?"
    exit 1
fi

echo "=========================================================="
echo " [*] Starting Docker Fleet Maintenance & Layer Cleanup"
echo "=========================================================="

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[*] Dangling Images to prune:"
    docker images --filter "dangling=true" -q
    echo "[*] Stopped Containers older than 72h:"
    docker ps -a --filter "status=exited" --filter "until=72h" -q
else
    echo "[1/4] Pruning dangling images..."
    docker image prune -f

    echo "[2/4] Removing stopped containers older than 72 hours..."
    docker container prune --filter "until=72h" -f

    echo "[3/4] Pruning unused custom networks..."
    docker network prune -f

    echo "[4/4] Pruning dangling build cache older than 7 days..."
    docker builder prune -f --filter "until=168h" 2>/dev/null || true
fi

echo "=========================================================="
echo " [*] Current Docker Disk Utilization:"
echo "=========================================================="
docker system df
