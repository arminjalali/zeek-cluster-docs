# 04 – Monitoring & Health Checks

This document explains how to use the monitoring scripts included in this repo.

Scripts live in `scripts/` and are typically deployed under `/opt/zeek/scripts/`.

---

## 1️⃣ Health check script

**File:** `scripts/health_check.sh`

Run:

```bash
sudo /opt/zeek/scripts/health_check.sh
```

It prints:

- `zeekctl status` (cluster node states)
- `zeekctl netstats` (packet/byte counts)
- System load, memory usage, disk space under `/opt/zeek`
- Basic interface stats for `ens160` from `/proc/net/dev`
- Last few entries from `notice.log`
- Log file sizes in `logs/current/`

---

## 2️⃣ Advanced monitoring script

**File:** `scripts/advanced_monitor.sh`

Run:

```bash
sudo /opt/zeek/scripts/advanced_monitor.sh
```

It shows:

- Detailed process status (`zeekctl status`)
- `zeekctl netstats` packet processing stats
- CPU load, memory usage, disk usage
- RX/TX packets and drops on `ens160`
- Log statistics (# of log files, total size)
- Notice summary from `notice.log`
- Performance metrics from `stats.log` (if present)
- Cluster health summary – running vs total nodes

---

## 3️⃣ Log management script

**File:** `scripts/log_management.sh`

Run:

```bash
sudo /opt/zeek/scripts/log_management.sh
```

It will:

- Show disk usage before cleanup
- If `logs/current/` is larger than a threshold (~5 GB), call `zeekctl cron` to rotate logs
- Compress `.log` files older than 1 day (`*.log.gz`)
- Move compressed logs older than 7 days into `/opt/zeek/log_backups/`
- Delete log backups older than 30 days
- Show disk usage after cleanup

Log lifecycle:

```text
Timeline: Today ── 1 day ── 7 days ── 30 days ──>
           │        │        │          │
           │        ├─ compress         │
           │        │        ├─ archive │
           │        │        │          ├─ delete

Logs:
  current/*.log   →   *.log.gz   →   log_backups/   →   removed
  (active)            (compressed)     (archived)       (expired)
```

---

## 4️⃣ Scheduling via cron

Example: health check every 5 minutes, log management daily at 03:00.

```bash
sudo crontab -e
```

Add:

```cron
*/5 * * * * /opt/zeek/scripts/health_check.sh >> /opt/zeek/logs/health_check.out 2>&1
0 3 * * *   /opt/zeek/scripts/log_management.sh >> /opt/zeek/logs/log_management.out 2>&1
```

---

## 5️⃣ Next steps

- Pipe outputs to your SIEM or log management
- Trigger alerts based on packet drop rates, node failures, or disk usage thresholds
