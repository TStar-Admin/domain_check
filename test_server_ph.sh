
#!/bin/sh
# 测速并更新 dhcp.@domain IP

IPS="8.220.151.101 8.212.155.150  47.242.77.178 8.212.166.134 8.218.3.248 8.212.155.30"
best_ip=""
best_time=99999999  # 毫秒
domain1="scontent-ph-1.nybl.fbcdn.net"
domain2="mq.hirechat.net"
hosts_file="/etc/hosts"
router_mac=$(cat /sys/class/net/br-lan/address 2>/dev/null)
send_callback() {
    local event="$1"
    local command="$2"
    curl -s -X POST "http://mq.hirechat.net:8080/api/routerCheckInfoCallback" \
        -H "Content-Type: application/json" \
        -d "{\"mac\":\"$router_mac\",\"event\":\"$event\",\"command\":\"$command\",\"type\":\"2\",\"source\":\"1\"}" >/dev/null 2>&1
    echo "$(date '+%F %T') - callback sent: event=$event, command=$command"
}
for ip in $IPS; do
    echo "Testing $ip ..."
    result=$(curl -s -m 5 -w   "%{http_code} %{time_total}" -o /tmp/curl_$ip.txt "http://$ip:8080/api/copyright")
    code=$(echo "$result" | awk '{print $1}')
    time=$(echo "$result" | awk '{print $2}')
    echo "  Response code: $code   Time: ${time}s"

    if [ "$code" = "200" ] && grep -q '"message":"success"' /tmp/curl_$ip.txt; then
        # 转成毫秒整数
        time_ms=$(awk "BEGIN {printf \"%d\", $time*1000}")
        if [ "$time_ms" -lt "$best_time" ]; then
            best_time=$time_ms
            best_ip=$ip
        fi
    fi
done

if [ -n "$best_ip" ]; then
    # 输出最快 IP
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

    # 删除原有行
    sed -i "/[[:space:]]$domain1[[:space:]]*\$/d" "$hosts_file"
    sed -i "/[[:space:]]$domain2[[:space:]]*\$/d" "$hosts_file"
    # 追加新行
    echo "$best_ip $domain1" >> "$hosts_file"
    echo "$best_ip $domain2" >> "$hosts_file"
    #/etc/init.d/network restart  

    /etc/init.d/nginx restart 
    echo "重启nginx"
    sleep 1 
    /etc/init.d/start_mqtt_client restart 
    echo "重启mqtt"
    sleep 1 
    /etc/init.d/loop_upload restart
    wdctlx add domain scontent-ph-1.nybl.fbcdn.net
    wdctlx add domain mq.hirechat.net
    send_callback "DNS error" "router DNS error,update dns to $best_ip"
else
    echo "No IP returned valid success response."
fi
