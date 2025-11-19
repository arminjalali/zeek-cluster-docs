#!/bin/bash
# Simple Zeek cluster health check script.

# Ensure zeek-cut is available (used for pretty log output)
if ! command -v zeek-cut >/dev/null 2>&1; then
  echo "Warning: zeek-cut not found in PATH. Some formatted outputs may not work."
fi

echo "=== Zeek Cluster Health Check ==="
echo "Time: $(date)"
echo

echo "1. Zeek Process Status:"
zeekctl status
echo

echo "2. Cluster Network Stats:"
zeekctl netstats
echo

echo "3. System Resources:"
echo "Load: $(uptime | awk '{print $(NF-2), $(NF-1), $NF}')"
echo "Memory: $(free -h | awk '/Mem/ {print $3 "/" $2}')"
echo "Disk: $(df -h /opt/zeek | awk 'END {print $4 " free"}')"
echo

IFACE="ens160"
echo "4. Local Network Interface Stats ($IFACE):"
if grep -q "$IFACE" /proc/net/dev; then
  cat /proc/net/dev | grep "$IFACE" | awk '{print "  Received: "$2" packets, Dropped: "$4" packets"}'
else
  echo "  Interface $IFACE not found in /proc/net/dev"
fi
echo

echo "5. Recent Security Notices:"
if [ -f "/opt/zeek/logs/current/notice.log" ]; then
  tail -5 /opt/zeek/logs/current/notice.log | zeek-cut ts note src msg 2>/dev/null || tail -5 /opt/zeek/logs/current/notice.log
else
  echo "  No notice.log found."
fi
echo

echo "6. Recent Errors (log files containing 'error'):"
find /opt/zeek/logs/current -name "*.log" -exec grep -li "error\|Error" {} \; 2>/dev/null | head -3
echo

echo "7. Log File Sizes (top 10):"
ls -lh /opt/zeek/logs/current/*.log 2>/dev/null | head -10 | awk '{print $5, $9}'
echo

echo "Health check completed."
