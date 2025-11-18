# 🛡️ Zeek Cluster – Production Deployment & Operations Guide

![Zeek](https://img.shields.io/badge/Zeek-Network%20Security-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange)
![Cluster](https://img.shields.io/badge/Mode-3%E2%80%91VM%20Cluster-green)
![AF--Packet](https://img.shields.io/badge/Capture-AF_PACKET-yellow)
![Status](https://img.shields.io/badge/Production-Ready-success)

---

## 📌 Overview

This repository contains everything needed to deploy and operate a **Zeek cluster** on **Ubuntu 24.04**, running on **three virtual machines (VMs)**:

- 1× **Manager / Proxy / Logger** (combined control node)
- 2× **Workers** using **AF_PACKET** for high-speed traffic capture

What you get:

- Installation instructions
- Cluster configuration (manager, proxy, logger, workers)
- AF_PACKET tuning and NIC offload disabling
- System (sysctl) optimization
- Health & monitoring scripts
- Log rotation / cleanup script
- Best practices for production use

---

## 🖥️ Deployment Environment (3 VMs)

This Zeek cluster is designed for **three VMs**.

### 1️⃣ Manager / Proxy / Logger

- **Role:** Central coordination, control, and logging
- **IP (placeholder):** `MANAGER_IP`
- Runs:
  - `manager`
  - `proxy`
  - `logger`

### 2️⃣ Worker 1

- **Role:** Packet capture & analysis
- **IP (placeholder):** `WORKER1_IP`
- Uses **AF_PACKET** on a capture interface (e.g. `ens160`)
- Runs:
  - `worker-1`

### 3️⃣ Worker 2

- **Role:** Packet capture & analysis
- **IP (placeholder):** `WORKER2_IP`
- Same pattern as Worker 1
- Runs:
  - `worker-2`

> ⚠️ All IPs are placeholders. Replace them with your real addresses, or with generic examples like `10.0.0.10`, `10.0.0.11`, `10.0.0.12` – avoid publishing your real private IPs publicly.

---

## 📡 Cluster Architecture (Anonymized)

```text
3-VM Zeek Cluster Layout

           ┌──────────────────────────────┐
           │   Manager / Proxy / Logger  │
           │          MANAGER_IP         │
           └───────────────┬─────────────┘
                           │
               ┌───────────┴───────────┐
               │                       │
      ┌────────▼────────┐     ┌────────▼────────┐
      │    Worker 1     │     │    Worker 2     │
      │    WORKER1_IP   │     │    WORKER2_IP   │
      └─────────────────┘     └─────────────────┘
```

---

## 📂 Repository Structure

```text
.
├── README.md
├── .gitignore
├── docs/
│   ├── 01-installation.md
│   ├── 02-cluster-setup.md
│   ├── 03-optimization.md
│   ├── 04-monitoring.md
│   ├── 05-troubleshooting.md
│   └── 06-best-practices.md
├── configs/
│   ├── node.cfg.example
│   ├── sysctl-zeek.conf
│   └── disable-offload.service
├── scripts/
│   ├── auto_install.sh
│   ├── health_check.sh
│   ├── advanced_monitor.sh
│   └── log_management.sh
└── images/
    └── .gitkeep
```

---

## 🚀 Quick Start

### 1️⃣ Clone the repository

```bash
git clone https://github.com/<your-user>/zeek-cluster.git
cd zeek-cluster
```

### 2️⃣ Run auto installer (on each node)

> Run this on **Ubuntu 24.04** manager and worker VMs.  
> Adjust interface name (`ens160` etc.) and paths if your environment differs.

```bash
sudo bash scripts/auto_install.sh
```

This will:

- Add the Zeek repository for Ubuntu 24.04
- Install Zeek
- Add `/opt/zeek/bin` to PATH (via `/etc/profile`)
- Apply Linux capabilities to `/opt/zeek/bin/zeek`
- Apply sysctl tuning (if `configs/sysctl-zeek.conf` is present)

### 3️⃣ Configure the cluster and deploy

- Copy and adjust `configs/node.cfg.example` → `/opt/zeek/etc/node.cfg`
- Set up passwordless SSH from manager to workers
- Then from the manager:

```bash
zeekctl deploy
zeekctl status
zeekctl netstats
```

---

## 📘 Documentation Index

| File | Description |
|------|-------------|
| `docs/01-installation.md`   | Install Zeek on Ubuntu 24.04 |
| `docs/02-cluster-setup.md`  | Cluster configuration (3-VM) |
| `docs/03-optimization.md`   | AF_PACKET, NIC tuning, sysctl |
| `docs/04-monitoring.md`     | Health & monitoring scripts |
| `docs/05-troubleshooting.md`| Common errors & debugging |
| `docs/06-best-practices.md` | Performance & security best practices |

---

## 🔧 Included Scripts

All scripts live in `scripts/`:

- `auto_install.sh` – Install Zeek + apply base sysctl tuning
- `health_check.sh` – Quick Zeek cluster health summary
- `advanced_monitor.sh` – Detailed cluster/node metrics
- `log_management.sh` – Log rotation, compression, archival, cleanup

Make them executable:

```bash
chmod +x scripts/*.sh
```

---

## 📗 Zeek Best Practices (Summary)

- Use **AF_PACKET** for high-throughput links (10G+)
- Disable NIC offloads (`gro`, `lro`, `tso`, `gso`, `ufo`, etc.) on capture interfaces
- Run Zeek with **capabilities**, not as root:
  ```bash
  sudo setcap cap_net_raw,cap_net_admin=+eip /opt/zeek/bin/zeek
  ```
- Keep capture interfaces dedicated (no user traffic)
- Monitor packet drops via `zeekctl netstats` and `/proc/net/dev`
- Use SSDs for log directories and offload long-term logs to SIEM / object storage

See `docs/06-best-practices.md` for full details.

---

## 🧪 Deployment Checklist

| Item | Status |
|------|--------|
| Zeek installed on all 3 VMs                 | ⬜ |
| AF_PACKET configured on workers             | ⬜ |
| NIC offloads disabled on capture interfaces | ⬜ |
| Sysctl tuning applied from `sysctl-zeek.conf` | ⬜ |
| Passwordless SSH (manager → workers)        | ⬜ |
| `node.cfg` configured correctly             | ⬜ |
| `zeekctl deploy` completes successfully     | ⬜ |
| Packet drops within acceptable range        | ⬜ |
| Log rotation working, disk usage stable     | ⬜ |

---

## 🙌 Contributing / Customizing

You can safely:

- Replace placeholders (`MANAGER_IP`, `WORKER1_IP`, `WORKER2_IP`)
- Adjust interfaces (`ens160`, `eth0`, etc.)
- Extend monitoring scripts for your SIEM/alerting
- Add diagrams under `images/` and refer to them from docs

Happy packet hunting 🐾
