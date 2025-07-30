#!/bin/sh
echo "hello openwrt, $(date '+%Y-%m-%d %H:%M:%S')"

IFACE="eth0"
MAC_ADDRESS=$(cat /sys/class/net/${IFACE}/address 2>/dev/null)

if [ -z "$MAC_ADDRESS" ]; then
  echo "❌ MAC 地址获取失败"
  exit 1
fi

UPTIME_SEC=$(cut -d. -f1 /proc/uptime)

URL="https://online.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
echo "访问URL: $URL"

response=$(wget -qO- "$URL")
echo "服务器返回：$response"
