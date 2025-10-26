#!/bin/bash

source ./config.env

LOG_FILE="./logs/server_health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
RAM_USAGE=$(free | awk '/Mem/{printf("%.2f"), $3/$2 * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
NET_STATS=$(ifstat 1 1 | awk 'NR==3{print "RX: "$1" KB/s, TX: "$2" KB/s"}')

OUTPUT="[$DATE] CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}% | DISK: ${DISK_USAGE}% | ${NET_STATS}"
echo "$OUTPUT" >> "$LOG_FILE"

alert=""

if (( ${CPU_USAGE%.*} > CPU_THRESHOLD )); 
then
  alert+="⚠️ High CPU Usage: ${CPU_USAGE}%\n"
fi

if (( ${RAM_USAGE%.*} > RAM_THRESHOLD )); 
then
  alert+="⚠️ High RAM Usage: ${RAM_USAGE}%\n"
fi

if (( ${DISK_USAGE%.*} > DISK_THRESHOLD )); 
then
  alert+="⚠️ Low Disk Space: ${DISK_USAGE}%\n"
fi

if [ -n "$alert" ]; 
then
  MESSAGE="Server Health Alert 🚨\n$alert\n$OUTPUT"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MESSAGE" >/dev/null 2>&1
fi
