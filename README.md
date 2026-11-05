# :whale: Production Docker Fleet Management & Security Hardening

[![Docker](https://img.shields.io/badge/Container%20Engine-Docker%2024%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![CIS Benchmark](https://img.shields.io/badge/Security-CIS%20Docker%20Benchmark-00C853?style=for-the-badge&logo=shield&logoColor=white)](scripts/cis-docker-audit.sh)
[![Portainer CE](https://img.shields.io/badge/Fleet%20UI-Portainer%20CE-13BEBB?style=for-the-badge&logo=portainer&logoColor=white)](https://portainer.io)
[![Watchtower](https://img.shields.io/badge/CI%2FCD-Watchtower%20Rolling%20Updates-F58220?style=for-the-badge&logo=docker&logoColor=white)](compose/docker-compose.yml)

A production-hardened Docker fleet deployment framework engineered for private cloud nodes. Enforces Center for Internet Security (CIS) daemon security baselines, prevents container breakout vulnerabilities (`no-new-privileges`), restricts inter-container communication (`icc: false`), caps log storage exhaustion, and automates rolling container maintenance via Watchtower.

---

## :triangular_ruler: Fleet Management Architecture

```mermaid
flowchart TD
    subgraph Host Kernel Layer
        Kernel[Linux Kernel 6.x / AppArmor / seccomp]
        Daemon[Hardened Docker Daemon<br/>live-restore / icc: false / max-size: 50m]
    end

    subgraph Management Tier
        Portainer[Portainer CE Fleet Manager :9443<br/>Role-Based Access Control]
        Watchtower[Watchtower Engine<br/>Automated Rolling Updates]
    end

    subgraph Automated Maintenance
        AuditScript[CIS Docker Benchmark Audit Script]
        PruneScript[Automated Zero-Downtime Pruner]
    end

    Kernel --> Daemon
    Daemon --> Portainer
    Daemon --> Watchtower
    AuditScript -->|Verifies Compliance| Daemon
    PruneScript -->|Cleans Dangling Layers| Daemon
```

---

## :shield: CIS Security Hardening Controls (`daemon.json`)

| Security Directive | Value | Production Rationale |
| :--- | :--- | :--- |
| `no-new-privileges` | `true` | Prevents privilege escalation attacks inside containers (`setuid`/`setgid`). |
| `icc` | `false` | Disables unrestricted Inter-Container Communication on default bridge. |
| `userland-proxy` | `false` | Routes container traffic directly through Linux kernel `iptables` for performance and security. |
| `live-restore` | `true` | Keeps containers alive without downtime when updating or restarting the Docker daemon. |
| `log-driver` | `json-file` | Implements rotating log caps (`50m`, max 3 files) preventing disk exhaustion. |

---

## :rocket: Deployment & Auditing

### 1. Apply Hardened Daemon Configuration
```bash
git clone https://github.com/Aryan-136/docker-infrastructure.git
cd docker-infrastructure

# Copy hardened daemon config
sudo cp configs/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
```

### 2. Run CIS Compliance Audit
```bash
chmod +x scripts/*.sh
./scripts/cis-docker-audit.sh
```

### 3. Launch Fleet Management Stack
```bash
docker compose -f compose/docker-compose.yml up -d
```

---

## :file_folder: Repository Layout
```text
.
â”œâ”€â”€ compose/
â”‚   â””â”€â”€ docker-compose.yml        # Portainer CE & Watchtower fleet manager
â”œâ”€â”€ configs/
â”‚   â””â”€â”€ daemon.json               # CIS-hardened Docker daemon configuration
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ cis-docker-audit.sh       # Automated CIS benchmark compliance scanner
â”‚   â””â”€â”€ cleanup-fleet.sh          # Safe zero-downtime layer pruner
â””â”€â”€ README.md                     # Security controls & operational manual
```