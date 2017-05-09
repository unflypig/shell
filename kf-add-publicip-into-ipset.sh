#Author:zhangtao@melinkr.com
#Data:2017年4月17日14:04:34
#Function:This scrip is used to add public ip into ipset list
#!/bin/sh
GLOBAL_MODE="3"
vpn_mode="`uci get /etc/kfconfig/kfconfig.vpn.mode`"
#check if ipv4 addr  valid
ipv4valid(){
    local ip=$1
    echo -e "$ip" |grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}$" -q
    if [ $? = 0 ];then
        echo "true"
    else
        echo "flase"
    fi
}
if [ "$vpn_mode" = "$GLOBAL_MODE" ];then
    public_ip="`curl http://checkip.amazonaws.com/`"
    public_ip_valid="`ipv4valid $public_ip`"
    if [ "$public_ip_valid" == "true" ];then
        ipset list inlist|grep $public_ip -q
        if [ "$?" != 0 ];then
            ipset add inlist $public_ip
        fi
    fi
fi
