# ðŸ³ Production Docker Infrastructure & Container Fleet Management

[![Docker](https://img.shields.io/badge/Docker-24.0%2B-blue?style=flat-square&logo=docker)](https://www.docker.com/)
[![Portainer](https://img.shields.io/badge/Portainer-CE%20Latest-teal?style=flat-square&logo=portainer)](https://www.portainer.io/)
[![Security](https://img.shields.io/badge/Daemon%20Hardening-CIS%20Compliant-red?style=flat-square&logo=shield)](./configs/daemon.json)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Production container orchestration stack featuring automated updates, resource constraints (CPU/RAM limits), daemon security hardening, centralized logging, and Portainer fleet management.

---

## ðŸ› ï¸ Architectural Features
- **Hardened `/etc/docker/daemon.json`**: Restricts rootless access, limits container log file size to avoid disk saturation, and isolates user namespaces.
- **Automated Rolling Updates**: Watchtower continuously monitors Docker Hub registries and updates base images gracefully with email notifications.
- **Isolated Overlay Networks**: Frontend, backend, database, and telemetry networks are segregated with no inter-network leakage.

---

## ðŸš€ Quick Deployment

```bash
git clone https://github.com/aryanpandya/docker-infrastructure.git
cd docker-infrastructure/compose
docker compose up -d
```
