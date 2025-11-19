# 🛡️ Zeek Cluster – Production Deployment & Operations Guide

![Zeek Version](https://img.shields.io/badge/Zeek-5.2.0-brightgreen)
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
> Tested with: Zeek X.Y on Ubuntu 24.04

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

> ⚠️ All IPs are placeholders. Replace them with your real addresses, or with generic examples like `10.0.0.10`, `10.0.0.11`, `10.0.0.12`
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
git clone https://github.com/arminjalali/zeek-cluster.git
cd zeek-cluster
```

---

### 2️⃣ Run auto installer (on each node)

> Run this on **all 3 Ubuntu 24.04 VMs**  
> – 1 Manager VM  
> – 2 Worker VMs  
>
> ⚠️ Must be executed **as root**  
> ⚙️ Adjust interface name (`ens160`) if needed

```bash
sudo bash scripts/auto_install.sh
```

This script will automatically:

- Add the Zeek repository for Ubuntu 24.04  
- Install Zeek  
- Add `/opt/zeek/bin` to PATH (via `/etc/profile`)  
- Apply Linux capabilities to `/opt/zeek/bin/zeek`  
- Apply sysctl tuning (if `configs/sysctl-zeek.conf` exists)

---

### 3️⃣ Configure the cluster (manager only)

> 💡 Only the **manager** needs `/opt/zeek/etc/node.cfg`.  
> Workers **DO NOT** need a node.cfg file.


Copy the template:

```bash
sudo cp configs/node.cfg.example /opt/zeek/etc/node.cfg
sudo nano /opt/zeek/etc/node.cfg
```

Update the following fields:

- `manager` IP  
- `worker` IPs  
- `interface=` (your NIC name)  
- `lb_procs=` (AF_PACKET worker count)

---

### 4️⃣ Set up passwordless SSH (manager → workers)

```bash
ssh-keygen -t rsa -b 4096 -C "zeekctl"
ssh-copy-id root@WORKER1_IP
ssh-copy-id root@WORKER2_IP
```

Verify:

```bash
ssh root@WORKER1_IP hostname
ssh root@WORKER2_IP hostname
```

---

### 5️⃣ Deploy the cluster (manager only)

```bash
zeekctl deploy
zeekctl status
zeekctl netstats
```

Expected result:

- Manager → running  
- Proxy → running  
- Logger → running  
- Worker-1 → running  
- Worker-2 → running  

---

## 📘 Documentation Index

| File | Description |
|------|-------------|
| [`docs/01-installation.md`](docs/01-installation.md)   | Install Zeek on Ubuntu 24.04 |
| [`docs/02-cluster-setup.md`](docs/02-cluster-setup.md)  | Cluster configuration (3-VM) |
| [`docs/03-optimization.md`](docs/03-optimization.md)   | AF_PACKET, NIC tuning, sysctl |
| [`docs/04-monitoring.md`](docs/04-monitoring.md)     | Health & monitoring scripts |
| [`docs/05-troubleshooting.md`](docs/05-troubleshooting.md)| Common errors & debugging |
| [`docs/06-best-practices.md`](docs/06-best-practices.md) | Performance & security best practices |

---

## 🔧 Included Scripts

All scripts live in [`scripts/`](scripts/):

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

🟩 = completed / verified
🟥 = planned / future work / optional enhancements


| Item | Status |
|------|--------|
| Zeek installed on all 3 VMs                 | 🟩 |
| AF_PACKET configured on workers             | 🟩 |
| NIC offloads disabled on capture interfaces | 🟩 |
| Sysctl tuning applied from `sysctl-zeek.conf` | 🟩 |
| Passwordless SSH (manager → workers)        | 🟩 |
| `node.cfg` configured correctly             | 🟩 |
| `zeekctl deploy` completes successfully     | 🟩 |
| Packet drops within acceptable range        | 🟩 |
| Log rotation working, disk usage stable     | 🟩 |
| SIEM integration (Elastic/Splunk/Wazuh)     | 🟥 |
| Grafana dashboards for Zeek metrics	      | 🟥 |
| Prometheus exporter for Zeek	              | 🟥 |
| Automatic AF_PACKET tuning per worker       | 🟥 |
| Auto-detect NIC model + apply optimal settings| 🟥 |
| High-availability (HA) manager failover     | 🟥 |
| Secure log shipping (Filebeat/Vector)	      | 🟥 |
| Centralized alerting & notifications	      | 🟥 |
| Web UI for cluster monitoring	              | 🟥 |

---

## 🙌 Contributing / Customizing

You can safely:

- Replace placeholders (`MANAGER_IP`, `WORKER1_IP`, `WORKER2_IP`)
- Adjust interfaces (`ens160`, `eth0`, etc.)
- Extend monitoring scripts for your SIEM/alerting
- Add diagrams under `images/` and refer to them from docs

Happy packet hunting 🐾
