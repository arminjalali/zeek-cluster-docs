# 01 – Zeek Installation (Ubuntu 24.04)

This document explains how to install Zeek on **Ubuntu 24.04** and do basic validation.

---

## 1️⃣ Add Zeek repository

```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list

curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null

sudo apt update
sudo apt install -y zeek
```

---

## 2️⃣ Add Zeek to PATH

Zeek is installed under `/opt/zeek`. Add the binaries to your PATH:

```bash
echo 'export PATH=$PATH:/opt/zeek/bin' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
which zeek
which zeekctl
```

---

## 3️⃣ Basic ZeekControl test

After installation on a node (standalone):

```bash
zeekctl deploy
zeekctl status
```

This confirms ZeekControl can start a simple instance. For cluster mode, you will replace the default `node.cfg` later.

---

## 4️⃣ Useful package search

Search installed packages:

```bash
dpkg -l | grep -i zeek
```

Or for a generic word:

```bash
dpkg -l | grep -i <word>
```

---

## 5️⃣ Next steps

Repeat installation on all three VMs (manager + 2 workers), then move on to:

- [`02-cluster-setup.md`](02-cluster-setup.md)
- [`03-optimization.md`](03-optimization.md)
