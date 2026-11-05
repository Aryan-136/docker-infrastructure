#!/usr/bin/env bash
# ==============================================================================
# CIS Docker Benchmark Automated Audit Script
# Author: Aryan Pandya (Aryan-136)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [*] Running CIS Docker Benchmark Compliance Check..."
echo "=========================================================="

# Check 1: Live Restore Enabled
echo -n "[1] Checking live-restore policy: "
if docker info --format '{{.LiveRestoreEnabled}}' | grep -q "true"; then
    echo "PASS (Enabled)"
else
    echo "WARN (live-restore disabled - containers stop during daemon restart)"
fi

# Check 2: Userland Proxy Disabled
echo -n "[2] Checking userland-proxy: "
if grep -q '"userland-proxy": false' /etc/docker/daemon.json 2>/dev/null; then
    echo "PASS (Disabled - direct iptables routing active)"
else
    echo "WARN (userland-proxy enabled)"
fi

# Check 3: Log Rotation Limits
echo -n "[3] Verifying container log rotation caps: "
if grep -q '"max-size"' /etc/docker/daemon.json 2>/dev/null; then
    echo "PASS (Log caps configured)"
else
    echo "WARN (No max-size limit found - disk exhaustion risk)"
fi

# Check 4: Containers Running as Root
echo "[4] Inspecting containers running with UID 0 (root):"
docker ps -q | xargs -r docker inspect --format '{{.Name}}: User={{.Config.User}}'

echo "=========================================================="
echo " [SUCCESS] CIS Docker audit completed."
echo "=========================================================="