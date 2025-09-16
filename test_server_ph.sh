
#!/bin/sh
# 测速并更新 dhcp.@domain IP

IPS="8.212.155.150 8.220.151.101 47.242.77.178 8.212.166.134"
best_ip=""
best_time=99999999  # 毫秒

for ip in $IPS; do
    echo "Testing $ip ..."
    result=$(curl -s -w "%{http_code} %{time_total}" -o /tmp/curl_$ip.txt "http://$ip:8080/api/copyright")
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

    # 更新 dhcp.@domain
    for s in $(uci show dhcp | grep "dhcp.@domain.*.name='mq.hirechat.net'" | cut -d'[' -f2 | cut -d']' -f1); do
        uci delete dhcp.@domain[$s]
    done
    uci add dhcp domain
    uci set dhcp.@domain[-1].name='mq.hirechat.net'
    uci set dhcp.@domain[-1].ip="$best_ip"
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    sleep 5
    /etc/init.d/network restart  
    sleep 1 
    /etc/init.d/nginx restart 
    sleep 1 
    /etc/init.d/start_mqtt_client restart 
    sleep 1 
    /etc/init.d/loop_upload restart
else
    echo "No IP returned valid success response."
fi
