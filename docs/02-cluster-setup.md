# 02 – Zeek Cluster Setup (3-VM)

This document describes how to configure Zeek in **cluster mode** across **three VMs**:

- 1× Manager / Proxy / Logger
- 2× Worker nodes

IPs are placeholders: `MANAGER_IP`, `WORKER1_IP`, `WORKER2_IP`.

---

## 1️⃣ Passwordless SSH (manager → workers)

From the **manager** node:

```bash
ssh-keygen -t rsa -b 4096 -C "zeekctl"    # press Enter for defaults

ssh-copy-id root@WORKER1_IP
ssh-copy-id root@WORKER2_IP
```

Test connectivity:

```bash
ssh root@WORKER1_IP "hostname"
ssh root@WORKER2_IP "hostname"
```

---

## 2️⃣ Hostnames and /etc/hosts

On each node, set a hostname:

```bash
sudo hostnamectl set-hostname <hostname>
bash -l
```

Optionally add entries to `/etc/hosts` on all nodes (avoid 127.0.0.1):

```text
MANAGER_IP   zeek-manager
WORKER1_IP   zeek-worker1
WORKER2_IP   zeek-worker2
```

---

## 3️⃣ Cluster configuration: node.cfg

On the **manager** node, edit:

```bash
sudo nano /opt/zeek/etc/node.cfg
```

Example cluster configuration:

```ini
# Zeek cluster node configuration (example 3-VM setup)
> Only the manager uses node.cfg. The workers do not need this file.

[logger-1]
type=logger
host=MANAGER_IP
env_vars=log_rotate_interval=3600

[manager]
type=manager
host=MANAGER_IP
env_vars=cluster_store_interval=300

[proxy-1]
type=proxy
host=MANAGER_IP

[worker-1]
type=worker
host=WORKER1_IP
interface=ens160
lb_method=af_packet
lb_procs=4
env_vars=af_packet_buffer_size=128*1024*1024

[worker-2]
type=worker
host=WORKER2_IP
interface=ens160
lb_method=af_packet
lb_procs=4
env_vars=af_packet_buffer_size=128*1024*1024
```

Adjust:

- `MANAGER_IP`, `WORKER1_IP`, `WORKER2_IP`
- `interface=ens160` → your capture interface
- `lb_procs=4` → number of capture processes (per worker)

Backup:

```bash
sudo cp /opt/zeek/etc/node.cfg /opt/zeek/etc/node.cfg.backup
```

---

## 4️⃣ Deploy and check

From the manager:

```bash
zeekctl deploy
zeekctl status
zeekctl netstats
```

Workers should show as `running`.

---

## 5️⃣ Check worker logs

From the manager:

```bash
ssh root@WORKER1_IP "tail -f /opt/zeek/logs/current/zeekctl.log"
ssh root@WORKER2_IP "tail -f /opt/zeek/logs/current/zeekctl.log"
```

Look for errors related to:

- Interface not found
- Permissions / capabilities
- AF_PACKET configuration

---

## 6️⃣ Metrics port (optional)

If you configure a metrics port (e.g. `MetricsPort = 9991`) in Zeek, ensure firewalls allow access only from trusted monitoring hosts.

---

## 7️⃣ Next steps

- Apply performance and AF_PACKET tuning: [`03-optimization.md`](docs/03-optimization.md)
- Set up monitoring scripts: [`docs/04-monitoring.md`](04-monitoring.md)
