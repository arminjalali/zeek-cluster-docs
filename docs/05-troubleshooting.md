# 05 – Troubleshooting Zeek Cluster

This document covers common issues and techniques to debug them.

---

## 1️⃣ Permissions and ownership

Confirm Zeek directory:

```bash
ls -ld /opt/zeek
```

Ensure Zeek’s runtime user (if not root) can write to:

- `/opt/zeek/logs`
- `/opt/zeek/spool`

Example fix (adjust user/group as needed):

```bash
sudo chown -R zeek:zeek /opt/zeek
```

---

## 2️⃣ Zeek processes not starting

From the manager:

```bash
zeekctl status
zeekctl deploy
```

If workers are `stopped` or `crashed`:

```bash
ssh root@WORKER1_IP "tail -n 50 /opt/zeek/logs/current/zeekctl.log"
ssh root@WORKER2_IP "tail -n 50 /opt/zeek/logs/current/zeekctl.log"
```

Look for:

- Interface not found (`ens160` vs `eth0`)
- Permissions / capabilities errors
- Syntax errors in `node.cfg`

---

## 3️⃣ No traffic in logs

On a worker:

```bash
sudo tcpdump -i ens160 -n -c 20
```

- If `tcpdump` shows no packets → check SPAN/TAP or mirror config
- If `tcpdump` shows packets but Zeek doesn’t log:

  - Verify `interface=` in `node.cfg`
  - Confirm worker status in `zeekctl status`
  - Check `/opt/zeek/logs/current/` for errors

---

## 4️⃣ Packet drops

On the manager:

```bash
zeekctl netstats
```

On each node:

```bash
cat /proc/net/dev | grep ens160
```

If you see many drops:

- Increase RX ring size: `ethtool -G ens160 rx 4096`
- Disable GRO/LRO & other offloads
- Increase `net.core.netdev_max_backlog`
- Reduce other workloads on the capture node
- Ensure disk I/O is not saturated

---

## 5️⃣ AF_PACKET configuration problems

Ensure:

- `lb_method=af_packet` is set for workers
- `lb_procs` matches how many worker processes you want per node
- Optional: `af_packet_buffer_size` is set via `env_vars` in `node.cfg`

If you experimented with manual AF_PACKET `fanout_id` settings, revert to cluster-controlled config to simplify.

---

## 6️⃣ Disk full due to logs

If `/opt/zeek` disk is nearly full:

- Run `scripts/log_management.sh`
- Ensure `zeekctl cron` is periodically running
- Move or delete very old logs
- Increase disk size or move logs to another mount

---

## 7️⃣ When in doubt

- Check `/opt/zeek/logs/current/debug.log` (if enabled)
- Check system logs: `journalctl -u zeek` or `/var/log/syslog`
- Capture a small pcap and test Zeek offline:

  ```bash
  tcpdump -i ens160 -w sample.pcap -c 1000
  zeek -r sample.pcap
  ```

- Compare cluster config with `configs/node.cfg.example`
