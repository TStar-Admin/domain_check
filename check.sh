#!/bin/sh
echo "hello openwrt, $(date '+%Y-%m-%d %H:%M:%S')"
MAC_ADDRESS=$(cat /sys/class/net/eth0/address)


UPTIME_SEC=$(cut -d. -f1 /proc/uptime)
response=$(wget -qO- "https://online.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC")
echo response;
