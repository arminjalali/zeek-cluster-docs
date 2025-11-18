#!/bin/bash
# Advanced Zeek cluster monitoring script.

echo "=== Zeek Advanced Cluster Monitor ==="
echo "Time: $(date)"
echo

echo "1. Detailed Process Status:"
zeekctl status
echo

echo "2. Packet Processing Statistics:"
zeekctl netstats
echo

echo "3. System Performance:"
echo "CPU Load: $(uptime)"
echo "Memory: $(free -m | awk '/Mem/ {printf "Used: %dMB/%dMB (%.1f%%)\n", $3, $2, $3/$2*100}')"
echo "Disk: $(df -h /opt/zeek | awk 'END {printf "%s used, %s free (%s)\n", $3, $4, $5}')"
echo

echo "4. Network Interface Details:"
interface="ens160"
if grep -q "$interface" /proc/net/dev; then
  echo "Interface: $interface"
  rx_packets=$(awk -v iface="$interface" '$0 ~ iface":" {print $2}' /proc/net/dev)
  tx_packets=$(awk -v iface="$interface" '$0 ~ iface":" {print $10}' /proc/net/dev)
  rx_drops=$(awk -v iface="$interface" '$0 ~ iface":" {print $4}' /proc/net/dev)
  tx_drops=$(awk -v iface="$interface" '$0 ~ iface":" {print $12}' /proc/net/dev)
  echo "  Received: $rx_packets packets, Dropped: $rx_drops packets"
  echo "  Transmitted: $tx_packets packets, Dropped: $tx_drops packets"
  if [ "${rx_packets:-0}" -gt 0 ] 2>/dev/null; then
    drop_percent=$(echo "scale=4; $rx_drops * 100 / $rx_packets" | bc 2>/dev/null || echo "0")
    echo "  Drop rate: $drop_percent% (Excellent: < 0.1%)"
  fi
else
  echo "  Interface $interface not found in /proc/net/dev"
fi
echo

echo "5. Zeek Log Statistics:"
log_dir="/opt/zeek/logs/current"
log_count=$(ls "$log_dir"/*.log 2>/dev/null | wc -l)
total_log_size=$(du -sh "$log_dir" 2>/dev/null | awk '{print $1}')
echo "  Active log files: $log_count"
echo "  Total log size: $total_log_size"
echo

echo "6. Recent Security Events:"
notice_file="/opt/zeek/logs/current/notice.log"
if [ -f "$notice_file" ]; then
  notice_count=$(wc -l < "$notice_file" 2>/dev/null || echo "0")
  echo "  Total notices: $notice_count"
  echo "  Last 3 notices:"
  tail -3 "$notice_file" 2>/dev/null | zeek-cut -d ts note src msg 2>/dev/null || tail -3 "$notice_file" 2>/dev/null
else
  echo "  No notice.log file found."
fi
echo

echo "7. Performance Metrics:"
stats_file="/opt/zeek/logs/current/stats.log"
if [ -f "$stats_file" ]; then
  echo "  Recent packet rates:"
  tail -1 "$stats_file" 2>/dev/null | zeek-cut -d ts peer packets_received events_proc 2>/dev/null || tail -1 "$stats_file" 2>/dev/null
else
  echo "  No stats.log file found."
fi
echo

echo "8. Cluster Health Summary:"
running_nodes=$(zeekctl status | grep -c running)
total_nodes=$(zeekctl status | grep -E 'running|stopped|crashed|failed' | wc -l)
echo "  Nodes running: $running_nodes/$total_nodes"
if [ "$total_nodes" -gt 0 ] && [ "$running_nodes" -eq "$total_nodes" ]; then
  echo "  Status: HEALTHY"
else
  echo "  Status: ISSUES DETECTED"
fi
echo

echo "=== Monitoring Completed ==="
