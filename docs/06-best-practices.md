# 06 – Zeek Best Practices Guide

This document summarizes recommended practices for a stable, performant Zeek cluster.

---

## 1️⃣ Packet capture & architecture

- Use **AF_PACKET** for 10G+ networks.
- Ensure capture interfaces are **dedicated**:
  - No management / user traffic on capture NICs if possible.
- Align:
  - Number of Zeek workers ↔ CPU cores / NIC queues.
- Validate mirror/SPAN/TAP configurations regularly.

---

## 2️⃣ Logging strategy

- Rotate logs daily or more often under heavy traffic.
- Compress older logs (`*.log` → `*.log.gz`).
- Use `/opt/zeek/log_backups` or remote storage (NFS/S3/SIEM).
- Monitor disk usage trends over time.
- Keep an eye on `notice.log` and `weird.log` for anomalies.

---

## 3️⃣ Performance tuning

- Increase receive and send buffer sizes:

  ```bash
  net.core.rmem_max=134217728
  net.core.wmem_max=134217728
  ```

- Increase network backlog:

  ```bash
  net.core.netdev_max_backlog=300000
  ```

- Raise file descriptor limits:

  ```bash
  fs.file-max=1000000
  ```

- Adjust NIC buffers and offloads:

  ```bash
  ethtool -G ens160 rx 4096 tx 4096
  ethtool -K ens160 gro off lro off
  ```

- Regularly check `zeekctl netstats` for drop trends.

---

## 4️⃣ Reliability & operations

- Use **passwordless SSH** for manager → worker control.
- Monitor health with cron-scheduled scripts:
  - `health_check.sh` every 5–15 minutes.
  - `log_management.sh` daily.
- Document:
  - Baseline performance
  - Typical packet rates
  - Expected log sizes

---

## 5️⃣ Security hardening

- Run Zeek with capabilities, not as full root:

  ```bash
  sudo setcap cap_net_raw,cap_net_admin=+eip /opt/zeek/bin/zeek
  ```

- Restrict management access via firewall/VPN.
- Lock down access to `/opt/zeek/logs` and `/opt/zeek/spool`.
- Forward critical notices to a SIEM or alerting system.

---

## 6️⃣ Scaling out

- Add more workers behind the same manager/proxy.
- Use multiple capture interfaces when needed.
- Consider separate clusters for:
  - Perimeter traffic
  - Internal east-west monitoring
  - High-value segments

This repository gives you a solid starting point for such scalable designs.
