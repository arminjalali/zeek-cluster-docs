# 03 – Optimization & AF_PACKET Tuning

This document focuses on capturing packets efficiently and tuning the system.

- AF_PACKET usage
- Capabilities (non-root capture)
- NIC offload disabling
- Network and sysctl tuning

---

## 1️⃣ AF_PACKET basics

Standard capture (via libpcap):

```bash
zeek -i eth0
```

AF_PACKET capture:

```bash
zeek -i af_packet::eth0
```

AF_PACKET uses the Linux kernel packet socket directly, which is more efficient for:

- High-speed interfaces (10G+)
- Multi-core processing
- Zeek clusters with multiple workers

---

## 2️⃣ Capabilities: run Zeek without root

Grant Zeek only the capabilities it needs:

```bash
sudo setcap cap_net_raw,cap_net_admin=+eip /opt/zeek/bin/zeek
```

This allows Zeek to open raw sockets and configure network interfaces without being full root.

Verify:

```bash
getcap /opt/zeek/bin/zeek
```

Expect something like:

```text
/opt/zeek/bin/zeek = cap_net_admin,cap_net_raw+eip
```

Apply on **all nodes**.

---

## 3️⃣ Disable NIC offloading on workers

Offloading features can cause checksum issues and mislead analyzers.

### Persistent service

On worker nodes, create:

```bash
sudo nano /etc/systemd/system/disable-offload.service
```

Paste:

```ini
[Unit]
Description=Disable NIC offloading for Zeek capture
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'IFACE=ens160; for offload in rx tx sg tso ufo gso gro lro; do /sbin/ethtool -K $IFACE $offload off || true; done'

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable disable-offload.service
sudo systemctl start disable-offload.service
sudo systemctl status disable-offload.service
```

### Temporary (for testing)

```bash
IFACE=ens160
for offload in rx tx sg tso ufo gso gro lro; do
  sudo ethtool -K $IFACE $offload off
done
```

---

## 4️⃣ Network optimization (workers)

Example tuning for `ens160`:

```bash
sudo ethtool -G ens160 rx 4096 tx 4096
sudo ethtool -K ens160 gro off lro off
sudo ethtool -C ens160 rx-usecs 0
```

Check:

```bash
ethtool -g ens160
ethtool -k ens160 | grep -E "generic-receive-offload|large-receive-offload"
```

---

## 5️⃣ System tuning (sysctl)

On all nodes, create `/etc/sysctl.d/99-zeek.conf`:

```bash
sudo nano /etc/sysctl.d/99-zeek.conf
```

Example content (also in `configs/sysctl-zeek.conf`):

```bash
# Network stack optimization
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.netdev_max_backlog=300000
net.core.somaxconn=1024

# Security / SYN handling
net.ipv4.tcp_syncookies=0
net.ipv4.tcp_max_syn_backlog=30000

# File descriptors
fs.file-max=1000000
```

Apply:

```bash
sudo sysctl -p /etc/sysctl.d/99-zeek.conf
```

---

## 6️⃣ AF_PACKET fanout notes (manual)

Example manual AF_PACKET test (on a worker):

```bash
zeek -i af_packet::ens160 AF_Packet::fanout_id=23 -C &
zeek -i af_packet::ens160 AF_Packet::fanout_id=23 -C &
```

- `-C` → ignore checksum errors
- `&` → background
- Same `fanout_id` on same interface → traffic split between processes

In cluster mode, this is usually handled for you via:

```ini
lb_method=af_packet
lb_procs=4
```

in `node.cfg`.

---

## 7️⃣ Next steps

- Configure monitoring & health scripts: [`04-monitoring.md`](docs/04-monitoring.md)
- Watch `zeekctl netstats` and `/proc/net/dev` for drops
