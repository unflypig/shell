#Author:zhangtao@melinkr.com
#Data:2017年4月18日11:03:23
#Function:This scrip is used to check port accessable
#!/bin/sh
LOG_PATH="/root/kflogs/kf-check-vps-port.log"
[ -f /root/kflogs ] || mkdir "/root/kflogs"
server_ips="`cat /etc/shadowsocks/config.json|grep -E '\"server\"'|awk -F ':' '{print $2}'|grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}'`"
while true;do
    for server_ip in $server_ips;do
        server_port="`cat /etc/shadowsocks/config.json|grep $server_ip|awk -F ':' '{print $3}'``"
        nc -v -z -w 1 $server_ip $server_port
        if [ "$?" = 0 ];then
            echo "[`date '+%y-%m-%d %H:%M:%S'`] connect to $server_ip $server_port success!" >> $LOG_PATH
        else
            echo "[`date '+%y-%m-%d %H:%M:%S'`] connect to $server_ip $server_port fail!" >> $LOG_PATH
        fi
    done
    sleep 1
done
