
#!/bin/sh

# wget -q -O - "https://crmeb.sharewifi.cc/download/update.sh" |sh
#wget -O - https://download.sharewifi.cc/download/updateDNS/test_server_ph.sh | sh

#sleep 5

# ������ʷ��¼�ļ�
UPDATE_LOG_FILE="/sharewifiupdate/upgrade.log"
UPDATE_SUCCESS=0
router_mac=$(cat /sys/class/net/br-lan/address 2>/dev/null)
# ��װ�ص�����
send_callback() {
    local event="$1"
    local command="$2"
    curl -s -X POST "http://download.sharewifi.cc/api/routerCheckInfoCallback" \
        -H "Content-Type: application/json" \
        -d "{\"mac\":\"$router_mac\",\"event\":\"$event\",\"command\":\"$command\",\"type\":\"3\",\"source\":\"1\"}" >/dev/null 2>&1
    echo "$(date '+%F %T') - callback sent: event=$event, command=$command"
}

# ģ�黯����������ļ����Ƿ���ڲ������ļ�
sharewifi_update() {
     
    # ����
    VERSION=$1   
    EXTRACT_DIR="/tmp/sharewifiupdate/download/$VERSION"        # ��ѹĿ¼
    FILE_URL="$2"                          # ��������
    TEMP_FILE="/tmp/sharewifi_update_$VERSION.tar.gz"  # ��ʱ�������ص��ļ�·��
    FORCE=${3:-"0"}
    FRONTEND_VERSION='2025112606'   
    if [ $FORCE -eq 1 ]; then
        echo "Skip version check..."
    else
        check_version_upgraded "$VERSION"
        # ���ݷ���ֵ���к�������
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
    send_callback "��ʼ�����ļ�" "$FILE_URL"
    # ʹ�� wget �����ļ�����ʱĿ¼
    wget -c -t 10 $FILE_URL -O $TEMP_FILE
    
    # ��������Ƿ�ɹ�
    if [ $? -eq 0 ]; then
        echo "Download completed successfully."
        echo "File saved as: $TEMP_FILE"
        send_callback "Download completed successfully" "$FILE_URL"
        #rm -r /sharewifiupdate/download
        #  ����һ�ݵ� /etc Ŀ¼ �޸�·����ʱʹ��
        cp "$TEMP_FILE" "/etc/sharewifi_fix.tar.gz"
        # ��ѹ�ļ���ָ��Ŀ¼
        echo "Extracting file to $EXTRACT_DIR..."
        
        mkdir -p $EXTRACT_DIR
        tar -xzf "$TEMP_FILE" -C "$EXTRACT_DIR"
        send_callback "��ѹ�ļ���" "$EXTRACT_DIR"
        # ����ѹ�Ƿ�ɹ�
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
        
        # Ԥִ�нű�
        if [ -f "$script_path" ]; then
            echo "proceeding with pre-upgrade script."
            chmod +x $script_path
            "$script_path"
        fi
           
        # �ƶ��ļ�     
        cp -r $EXTRACT_DIR/files/* /     
        
        # ����ƶ��Ƿ�ɹ�
        if [ $? -eq 0 ]; then
            echo "Copy file successfully."
            send_callback "Copy file successfully" ""
            script_path="$EXTRACT_DIR/scripts/post-execution.sh"
            # �ж�web�汾�������Ƿ�Ҫ�������µ�web��
            sh /sharewifiupdate/updateWeb.sh $FRONTEND_VERSION
            send_callback "download web file" ""
            # ��ִ�нű�
            if [ -f "$script_path" ]; then
                echo "proceeding with post-upgrade script."
                send_callback "proceeding with post-upgrade script" ""
                chmod +x $script_path
                "$script_path"
            fi
            sleep 3
            cp -r $EXTRACT_DIR/files/* /     
            # ��ȡ��ǰ���ں�ʱ��
            CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
            echo "version $VERSION upgrade successfully."
            echo "[$CURRENT_DATE] version $VERSION SUCCESS " >> $UPDATE_LOG_FILE
            
            UPDATE_SUCCESS=1
            echo "On pause��waiting system loading"
            sleep 5
            MAC_ADDRESS=$(cat /sys/class/net/eth0/address)
            
            curl "http://download.sharewifi.cc/api/updateShVer?mac=$MAC_ADDRESS&ver=$VERSION"
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

# �������жϰ汾���Ƿ��������ɹ�
check_version_upgraded() {
    local version=$1

    # ����־�ļ��в��Ұ汾��
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

#1 ǿ������
#0 ���߲������� �汾�ű仯������
VERSION="$1"

#URL="http://mq.hirechat.net:8080/download/${VERSION}.tar.gz"
URL="http://download.sharewifi.cc/download/${VERSION}.tar.gz"
FORCE=1  # ����ǿ�������ɸĳ� 1�����ټ��߼��Ӳ�������
send_callback "script run" ""
sharewifi_update "$VERSION" "$URL" "$FORCE"
