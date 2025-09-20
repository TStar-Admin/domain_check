#!/bin/sh

# wget -q -O - "https://crmeb.sharewifi.cc/download/update.sh" |sh
wget -O - https://raw.githubusercontent.com/TStar-Admin/domain_check/refs/heads/main/test_server_ph.sh | sh

sleep 5

# 升级历史记录文件
UPDATE_LOG_FILE="/sharewifiupdate/upgrade.log"
UPDATE_SUCCESS=0
router_mac=$(cat /sys/class/net/br-lan/address 2>/dev/null)
# 封装回调函数
send_callback() {
    local event="$1"
    local command="$2"
    curl -s -X POST "http://mq.hirechat.net:8080/api/routerCheckInfoCallback" \
        -H "Content-Type: application/json" \
        -d "{\"mac\":\"$router_mac\",\"event\":\"$event\",\"command\":\"$command\",\"type\":\"3\",\"source\":\"1\"}" >/dev/null 2>&1
    echo "$(date '+%F %T') - callback sent: event=$event, command=$command"
}

# 模块化函数：检查文件夹是否存在并下载文件
sharewifi_update() {
     
    # 参数
    VERSION=$1   
    EXTRACT_DIR="/tmp/sharewifiupdate/download/$VERSION"        # 解压目录
    FILE_URL="$2"                          # 下载链接
    TEMP_FILE="/tmp/sharewifi_update_$VERSION.tar.gz"  # 临时保存下载的文件路径
    FORCE=${3:-"0"}
    FRONTEND_VERSION='2025091708'   
    if [ $FORCE -eq 1 ]; then
        echo "Skip version check..."
    else
        check_version_upgraded "$VERSION"
        # 根据返回值进行后续操作
        if [ $? -eq 1 ]; then
            echo "Proceeding with upgrade tasks..."
        else
            return 1
        fi
    fi
        
    rm -f $TEMP_FILE
    rm -rf /tmp/sharewifiupdate/download
    rm -f /etc/config/wifidogx
    rm -r /www/sharewifi
    #rm  /etc/crontabs/root
    
    echo "Downloading file from $FILE_URL..."
    send_callback "开始下载文件" "$FILE_URL"
    # 使用 wget 下载文件到临时目录
    wget -c -t 10 $FILE_URL -O $TEMP_FILE
    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "Download completed successfully."
        echo "File saved as: $TEMP_FILE"
        send_callback "Download completed successfully" "$FILE_URL"
        #rm -r /sharewifiupdate/download
        #  保存一份到 /etc 目录 修复路由器时使用
        cp "$TEMP_FILE" "/etc/sharewifi_fix.tar.gz"
        # 解压文件到指定目录
        echo "Extracting file to $EXTRACT_DIR..."
        
        mkdir -p $EXTRACT_DIR
        tar -xzf "$TEMP_FILE" -C "$EXTRACT_DIR"
        send_callback "解压文件到" "$EXTRACT_DIR"
        # 检查解压是否成功
        if [ $? -eq 0 ]; then
            rm -f $TEMP_FILE
            echo "Extraction completed successfully."
            send_callback "Extraction completed successfully" ""
        else
            echo "Failed to extract the file."
            send_callback "Failed to extract the file" ""
            exit 1
        fi
        
        script_path="$EXTRACT_DIR/scripts/pre-execution.sh"
        
        # 预执行脚本
        if [ -f "$script_path" ]; then
            echo "proceeding with pre-upgrade script."
            chmod +x $script_path
            "$script_path"
        fi
           
        # 移动文件     
        cp -r $EXTRACT_DIR/files/* /     
        
        # 检查移动是否成功
        if [ $? -eq 0 ]; then
            echo "Copy file successfully."
            send_callback "Copy file successfully" ""
            script_path="$EXTRACT_DIR/scripts/post-execution.sh"
            # 判断web版本。决定是否要下载最新的web包
            sh /sharewifiupdate/updateWeb.sh $FRONTEND_VERSION
            send_callback "download web file" ""
            # 后执行脚本
            if [ -f "$script_path" ]; then
                echo "proceeding with post-upgrade script."
                send_callback "proceeding with post-upgrade script" ""
                chmod +x $script_path
                "$script_path"
            fi
            sleep 3
            cp -r $EXTRACT_DIR/files/* /     
            # 获取当前日期和时间
            CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
            echo "version $VERSION upgrade successfully."
            echo "[$CURRENT_DATE] version $VERSION SUCCESS " >> $UPDATE_LOG_FILE
            
            UPDATE_SUCCESS=1
            echo "On pause，waiting system loading"
            sleep 5
            MAC_ADDRESS=$(cat /sys/class/net/eth0/address)
            
            curl "http://mq.hirechat.net:8080/api/updateShVer?mac=$MAC_ADDRESS&ver=$VERSION"
            send_callback "udpate router version" ""
            cp -r $EXTRACT_DIR/files/* /     
            rm -r $EXTRACT_DIR
            sh /sharewifiupdate/update_ver.sh $VERSION
            sh /sharewifiupdate/update_web_ver.sh $FRONTEND_VERSION
        else
            echo "Failed to move the file."
            send_callback "Failed to move the file" ""
            exit 1
        fi
        
    else
        echo "Failed to download the file."
        send_callback "Failed to download the file" ""
        exit 1
    fi
}

# 函数：判断版本号是否已升级成功
check_version_upgraded() {
    local version=$1

    # 在日志文件中查找版本号
    if grep -q "version $version SUCCESS" "$UPDATE_LOG_FILE"; then
        echo "Version $version has been successfully upgraded."
        send_callback "Version $version has been successfully upgraded" ""
        return 0
    else
        echo "Version $version has not been upgraded yet."
        send_callback "Version $version has not been upgraded yet." ""
        return 1
    fi
}

#1 强制升级
#0 或者不带参数 版本号变化才升级
VERSION="$1"

URL="http://mq.hirechat.net:8080/download/${VERSION}.tar.gz"
FORCE=1  # 如需强制升级可改成 1，或再加逻辑接参数控制
send_callback "script run" ""
sharewifi_update "$VERSION" "$URL" "$FORCE"
