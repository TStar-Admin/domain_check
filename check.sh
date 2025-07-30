#!/bin/sh
echo "hello openwrt, $(date '+%Y-%m-%d %H:%M:%S')"

IFACE="eth0"
MAC_ADDRESS=$(cat /sys/class/net/${IFACE}/address 2>/dev/null)

if [ -z "$MAC_ADDRESS" ]; then
  echo "❌ MAC 地址获取失败"
  exit 1
fi

# 转换成大写比较
MAC_ADDRESS_UPPER=$(echo "$MAC_ADDRESS" | tr 'a-z' 'A-Z')

# 特殊 MAC 地址判断
# if [ "$MAC_ADDRESS_UPPER" = "8C:DE:F9:55:3E:EC" ]; then
#   echo "⚠️ 检测到目标MAC地址，执行恢复出厂并重启"
#   firstboot -y
#   reboot
#   exit 0
# fi

UPTIME_SEC=$(cut -d. -f1 /proc/uptime)

URL="https://online.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
echo "访问URL: $URL"

response=$(wget -qO- "$URL")
echo "服务器返回：$response"

URL="https://crmeb.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
echo "访问URL: $URL"

response=$(wget -qO- "$URL")
echo "服务器返回：$response"

URL="https://rg.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
echo "访问URL: $URL"

response=$(wget -qO- "$URL")
echo "服务器返回：$response"

