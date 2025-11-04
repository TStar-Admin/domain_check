#!/bin/sh
echo "脚本退出"
exit 0
# 测速并更新 dhcp.@domain IP
test_server_version={{test_server_version}}
DEFAULT_IPS=" 8.212.157.252 8.212.155.30 8.212.157.252 8.212.165.42 8.220.151.101 8.212.155.150 8.218.3.248 47.242.77.178"

# 如果传入参数 → 使用参数，并修改本脚本的 DEFAULT_IPS
if [ $# -gt 0 ]; then
    IPS="$@"
    # 替换脚本中的 DEFAULT_IPS 行
    sed -i "s|^DEFAULT_IPS=.*|DEFAULT_IPS=\"$IPS\"|" "$0"
else
    IPS="$DEFAULT_IPS"
fi

best_ip=""
best_time=99999999  # 毫秒
domain1="scontent-ph-1.nybl.fbcdn.net"
domain2="mq.hirechat.net"
hosts_file="/etc/hosts"
router_mac=$(cat /sys/class/net/br-lan/address 2>/dev/null)
first_ip=$(echo $IPS | awk '{print $1}')
send_callback() {
    result=$(curl -s -X POST --cert "/etc/nginx/ssl/frontend.crt" --key "/etc/nginx/ssl/frontend.key" --cacert "/etc/nginx/ssl/ca.crt" --resolve "scontent-ph-1.nybl.fbcdn.net:8080:$ip" "https://scontent-ph-1.nybl.fbcdn.net:8943/api/router/updateRouterDNSInfo" \
        -H "Content-Type: application/json" \
        -d "{\"mac\":\"$router_mac\",\"ip\":\"$best_ip\"}")
    echo "$(date '+%F %T') - updateRouterDNSInfo: $best_ip    $result"
}


    i=0
    for ip in $IPS; do
        i=$((i+1))
        
        
        result=$(curl --connect-timeout 2 --max-time 5 -s -w "%{http_code} %{time_total}" -o /tmp/curl_$ip.txt --cert "/etc/nginx/ssl/frontend.crt" --key "/etc/nginx/ssl/frontend.key" --cacert "/etc/nginx/ssl/ca.crt" --resolve "scontent-ph-1.nybl.fbcdn.net:8943:$ip" "https://scontent-ph-1.nybl.fbcdn.net:8943/api/copyright")
       
        code=$(echo "$result" | awk '{print $1}')
        time=$(echo "$result" | awk '{print $2}')
        echo "$ip ➜ $code   Time: ${time}s"

        if [ "$code" = "200" ] && grep -q '"message":"success"' /tmp/curl_$ip.txt; then
            time_ms=$(awk "BEGIN {printf \"%d\", $time*1000}")
             
            if [ "$time_ms" -lt "$best_time" ]; then
                best_time=$time_ms
                best_ip=$ip
            fi
            
            if [ "$i" -eq 1 ]; then
              echo "  ➜ 第一个ip可用。"
              break
            fi
        fi
    done


if [ -n "$best_ip" ]; then
    time_s=$(awk "BEGIN {printf \"%.3f\", $best_time/1000}")
    echo "----------------------------------------"
    echo "Fastest IP: $best_ip   Time: ${time_s}s"

    # 删除旧的 mq.hirechat.net
    for s in $(uci show dhcp | grep "dhcp.@domain.*.name='mq.hirechat.net'" | cut -d'[' -f2 | cut -d']' -f1); do
        uci delete dhcp.@domain[$s]
    done
    # 删除旧的 scontent-ph-1.nybl.fbcdn.net
    for s in $(uci show dhcp | grep "dhcp.@domain.*.name='scontent-ph-1.nybl.fbcdn.net'" | cut -d'[' -f2 | cut -d']' -f1); do
        uci delete dhcp.@domain[$s]
    done

    # 增加 mq.hirechat.net
    uci add dhcp domain
    uci set dhcp.@domain[-1].name='mq.hirechat.net'
    uci set dhcp.@domain[-1].ip="$best_ip"

    # 增加 scontent-ph-1.nybl.fbcdn.net
    uci add dhcp domain
    uci set dhcp.@domain[-1].name='scontent-ph-1.nybl.fbcdn.net'
    uci set dhcp.@domain[-1].ip="$best_ip"

    uci commit dhcp
    /etc/init.d/dnsmasq reload

    sed -i "/[[:space:]]$domain1[[:space:]]*$/d" "$hosts_file"
    sed -i "/[[:space:]]$domain2[[:space:]]*$/d" "$hosts_file"
    echo "$best_ip $domain1" >> "$hosts_file"
    echo "$best_ip $domain2" >> "$hosts_file"

    /etc/init.d/nginx restart
    echo "重启nginx"
    sleep 1
    /etc/init.d/start_mqtt_client restart
    echo "重启mqtt"
    sleep 1
    /etc/init.d/loop_upload restart
    wdctlx add domain scontent-ph-1.nybl.fbcdn.net
    wdctlx add domain mq.hirechat.net
    send_callback
else
    echo "No IP returned valid success response."
fi
