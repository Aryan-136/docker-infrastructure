#!/usr/bin/env bash
# ==============================================================================
# CIS Docker Benchmark Automated Audit Script
# Author: Aryan Pandya (Aryan-136)
# ==============================================================================
set -euo pipefail

CONFIG_PATH="${DOCKER_DAEMON_JSON:-/etc/docker/daemon.json}"
if [[ ! -f "$CONFIG_PATH" && -f "configs/daemon.json" ]]; then
    CONFIG_PATH="configs/daemon.json"
fi

PASS_COUNT=0
WARN_COUNT=0

pass() {
    printf "[PASS] %s\n" "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
    printf "[WARN] %s\n" "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

echo "=========================================================="
echo " [*] Running CIS Docker Benchmark Compliance Check..."
echo " [*] Evaluated config: ${CONFIG_PATH}"
echo "=========================================================="

# Prerequisite: Check Docker CLI & Daemon
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker CLI not found. Please install Docker before running audit."
    exit 2
fi

DAEMON_RUNNING=true
if ! docker info >/dev/null 2>&1; then
    echo "NOTICE: Docker daemon is not running. Evaluating static configuration files only."
    DAEMON_RUNNING=false
fi

# Check 1: Live Restore Enabled (CIS 2.14)
if [[ "$DAEMON_RUNNING" == "true" ]]; then
    if [[ "$(docker info --format '{{.LiveRestoreEnabled}}' 2>/dev/null)" == "true" ]]; then
        pass "live-restore is enabled (containers survive daemon reload)"
    else
        warn "live-restore is disabled (containers will terminate during daemon restarts)"
    fi
elif grep -Eq '"live-restore"\s*:\s*true' "$CONFIG_PATH" 2>/dev/null; then
    pass "live-restore configured in ${CONFIG_PATH}"
else
    warn "live-restore not configured in ${CONFIG_PATH}"
fi

# Check 2: Userland Proxy Disabled (CIS 2.15)
if grep -Eq '"userland-proxy"\s*:\s*false' "$CONFIG_PATH" 2>/dev/null; then
    pass "userland-proxy is disabled (direct kernel iptables routing)"
else
    warn "userland-proxy is enabled or unset (risk of hairpin NAT latency)"
fi

# Check 3: Log Rotation Limits (CIS 2.12)
if grep -Eq '"max-size"' "$CONFIG_PATH" 2>/dev/null; then
    pass "Container log rotation caps configured"
else
    warn "No max-size limit found (disk exhaustion vulnerability)"
fi

# Check 4: Default no-new-privileges (CIS 2.1)
if grep -Eq '"no-new-privileges"\s*:\s*true' "$CONFIG_PATH" 2>/dev/null; then
    pass "no-new-privileges baseline enabled"
else
    warn "no-new-privileges is not set to true in ${CONFIG_PATH}"
fi

# Check 5: Inter-Container Communication on Default Bridge (CIS 2.2)
if grep -Eq '"icc"\s*:\s*false' "$CONFIG_PATH" 2>/dev/null; then
    pass "Inter-container communication (icc) disabled on default bridge"
else
    warn "icc is enabled on default bridge (unrestricted container traffic)"
fi

# Check 6: Runtime Privileged Containers (CIS 5.4)
if [[ "$DAEMON_RUNNING" == "true" ]]; then
    privileged_ids=$(docker ps --quiet --filter "privileged=true")
    if [[ -z "$privileged_ids" ]]; then
        pass "No running containers in privileged mode"
    else
        warn "Privileged containers detected: ${privileged_ids}"
    fi

    # Check 7: Inspect Containers Running as UID 0 (root)
    container_ids=$(docker ps --quiet)
    if [[ -n "$container_ids" ]]; then
        root_containers=0
        while IFS= read -r cid; do
            user=$(docker inspect --format '{{.Config.User}}' "$cid")
            name=$(docker inspect --format '{{.Name}}' "$cid")
            if [[ -z "$user" || "$user" == "0" || "$user" == "root" ]]; then
                root_containers=$((root_containers + 1))
            fi
        done <<< "$container_ids"

        if [[ "$root_containers" -eq 0 ]]; then
            pass "All running containers specify a non-root User"
        else
            warn "${root_containers} container(s) running as root (UID 0)"
        fi
    else
        pass "No running containers to inspect for UID 0"
    fi
fi

echo "=========================================================="
printf " [AUDIT COMPLETE] %d checks passed, %d warnings.\n" "$PASS_COUNT" "$WARN_COUNT"
echo "=========================================================="

if [[ "$WARN_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
