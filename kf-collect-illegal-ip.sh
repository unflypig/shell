#!/bin/bash
PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
#Author:zhangtao@melinkr.com
#Data:2017年8月23日11:30:27
#Function:collect illegal ip via nslookup
LOG_PATH="/tmp/dns.log"
DNSMASQ_VER="2.76"
DNSMASQ_PKT_SAVE_PATH="/root/dnsmasq-2.76.tar.xz"
DNSMASQ_SRC_DIR="/root/dnsmasq-2.76"
DNSMASQ_PKT_MD5="00f5ee66b4e4b7f14538bf62ae3c9461"
DNSMASQ_PKT_URL="http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.76.tar.xz"
FORBIDDEN_DOMAIN_PATH="/etc/forbiddendomain.list"
HOST_CHANGE="false"
#This flag is change to "true" fater hosts file be changed
#we have to restart dnsmasq
kf_install_dnsmasq(){
    #check dnmasq version 
    local retry_time=3
    local dnsmasq_md5="0000000000"
    local current_dns_ver="`dnsmasq -v|grep 'Dnsmasq version'|grep -oE '[0-9]{1,2}\.[0-9]{1,2}'`"
    if [ "$current_dns_ver" != "$DNSMASQ_VER" ];then
        while [ "$dnsmasq_md5" != "$DNSMASQ_PKT_MD5" ];do
            echo "dnsmasq install pakage is error, retry get!" >> $LOG_PATH
            if [ $retry_time -lt 1 ];then
                echo "downloca dnsmasq install tar fail after savral retry, give up!" >> $LOG_PATH
                exit 0
            fi
            wget $DNSMASQ_PKT_URL -O $DNSMASQ_PKT_SAVE_PATH
            dnsmasq_md5="`md5sum $DNSMASQ_PKT_SAVE_PATH |grep -oE '[0-9a-z]{32}'`"
            retry_time=`expr $retry_time - 1`
            sleep 1
        done
        cd /root
        tar -xf dnsmasq-2.76.tar.xz
        cd $DNSMASQ_SRC_DIR
        make install
    else
        echo "dnsmasq have already installed, give up!" >> $LOG_PATH
    fi
}
kf_install_nslookup(){
    which nslookup > /dev/null
    if [ $? != 0 ];then
        yum install bind-utils -y
    fi
}
kf_install_ipset(){
    which ipset > /dev/null
    if [ $? != 0 ];then
        yum install ipset -y
    fi
}
kf_install_soft(){
    local soft_name=$1
    local yum_name=$2
    which $soft_name > /dev/null
    if [ $? != 0 ];then
        yum install $yum_name -y
    fi
}
kf_add_ipset_list(){
    ipset list|grep forbidden -q
    if [ $? != 0 ] ;then
        ipset create forbidden hash:ip
    else
        echo "forbidden ipset already exist" >> $LOG_PATH
    fi
}
kf_start_dnsmasq(){
    #start dnsmasq if it is not runnig
    local prc_num="`ps aux|grep dnsmasq|grep -v grep |wc -l`" 
    if [ "$prc_num" -lt 1 ];then
        local dnsmasq_cmd_path="`which dnsmasq`"
        if [ $dnsmasq_cmd_path ];then
            $dnsmasq_cmd_path
        fi
    fi
}
kf_restart_dnsmasq(){
    pkill dnsmasq
    local dnsmasq_cmd_path="`which dnsmasq`"
    if [ $dnsmasq_cmd_path ];then
        $dnsmasq_cmd_path
    fi
}
#check iptables rules if not exist, add it
kf_check_iptable_rules(){
    rule_nums="`iptables -t nat -L|grep 127.0.0.1:53|grep udp|grep DNAT|wc -l`"
    if [ "$rule_nums" -lt 1 ];then
        iptables -t nat -I OUTPUT -p udp -d 8.8.4.4 --dport 53 -j DNAT --to-destination 127.0.0.1:53
    fi
    rule_nums="`iptables -t nat -L|grep 127.0.0.1:53|grep tcp|grep DNAT|wc -l`"
    if [ "$rule_nums" -lt 1 ];then
        iptables -t nat -I OUTPUT -p tcp -d 8.8.4.4 --dport 53 -j DNAT --to-destination 127.0.0.1:53
    fi
    rule_nums="`iptables -t raw -L|grep match-set|grep forbidden|wc -l`"
    if [ "$rule_nums" -lt 1 ];then
        iptables -t raw -I OUTPUT -m set --match-set forbidden dst -j DROP
    fi
}
kf_add_ip_into_ipset(){
    illegal_domain_list="`cat $FORBIDDEN_DOMAIN_PATH`"
    for domain in $illegal_domain_list
    do
        if [ $domain ];then
            #if hosts file is not include this domain, we should add it
            domain_exist="`cat /etc/hosts |grep $domain -q > /dev/null;echo $?`"
            if [ "$domain_exist" != "0" ];then
                echo "127.0.0.1 $domain" >> /etc/hosts
                HOST_CHANGE="true"
            fi
            #we should get ip of this domian then add it into ipset 
            result="`nslookup $domain 8.8.8.8| grep "Address: " | awk -F " " '{print$2}'`"
            for ip in $result;do
                if [ $ip ];then
                    ipset add  forbidden $ip > /dev/null
                fi
            done 
        fi
    done
}
kf_install_soft "nslookup" "bind-utils"
kf_install_soft "ipset" "ipset"
kf_install_soft "xz" "xz"
kf_install_dnsmasq
kf_add_ipset_list
kf_start_dnsmasq
kf_check_iptable_rules
kf_add_ip_into_ipset
#get illegal domain list
#if hosts file was changed we have to restart dnsmasq
if [ "$HOST_CHANGE" = "true" ];then
    kf_restart_dnsmasq
fi
