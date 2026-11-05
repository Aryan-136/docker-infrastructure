#!/usr/bin/env bash
# ==============================================================================
# Docker Production Fleet Automated Cleanup
# Safe pruning preserving persistent volumes
# ==============================================================================
set -euo pipefail

echo "[*] Pruning dangling images..."
docker image prune -f

echo "[*] Removing stopped containers older than 72 hours..."
docker container prune --filter "until=72h" -f

echo "[*] Checking Docker disk utilization:"
docker system df