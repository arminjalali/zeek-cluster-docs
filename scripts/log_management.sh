#!/bin/bash
# Log rotation and cleanup for Zeek logs.

echo "=== Zeek Log Management ==="
echo "Date: $(date)"
echo

LOG_DIR="/opt/zeek/logs"
BACKUP_DIR="/opt/zeek/log_backups"
CURRENT_LOGS="$LOG_DIR/current"

mkdir -p "$BACKUP_DIR"

echo "Disk usage BEFORE cleanup:"
df -h "$LOG_DIR"
echo

# Threshold: 5,000,000 KB (~5 GB) – adjust if needed
current_size=$(du -s "$CURRENT_LOGS" 2>/dev/null | awk '{print $1}')
if [ "${current_size:-0}" -gt 5000000 ]; then
  echo "[*] Large log volume detected in $CURRENT_LOGS (size: ${current_size} KB). Rotating via zeekctl cron..."
  zeekctl cron
else
  echo "[*] Log size under threshold, no forced rotation."
fi
echo

echo "[*] Compressing log files older than 1 day..."
find "$LOG_DIR" -type f -name "*.log" -mtime +1 -exec gzip -9 {} \; 2>/dev/null
echo

echo "[*] Archiving compressed logs older than 7 days to $BACKUP_DIR..."
find "$LOG_DIR" -type f -name "*.log.gz" -mtime +7 -exec mv {} "$BACKUP_DIR"/ \; 2>/dev/null
echo

echo "[*] Deleting backups older than 30 days from $BACKUP_DIR..."
find "$BACKUP_DIR" -type f -name "*.log.gz" -mtime +30 -delete 2>/dev/null
echo

echo "Disk usage AFTER cleanup:"
df -h "$LOG_DIR"
echo

echo "Log management completed."
