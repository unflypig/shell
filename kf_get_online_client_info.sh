#Author:zhangtao@melinkr.com
#Data:2016年08月06日09:52:27
#Function:This script is used to ganarate a file,include online client mac,IP,name,ifhost(this flag tell you who is setting router by web page now 1 is setting) and so on
#Example
#mac                       ip                 name      ifhost      
#64:00:6a:35:a1:66         192.168.133.32     huxz      1
#64:00:6a:35:a1:22         192.168.133.31     androd    0

#!/bin/sh
ONLINECLIENTINFOCONF="/tmp/onlineclientinfo"
printf "%-19s" "mac" > $ONLINECLIENTINFOCONF
printf "%-17s" "ip" >> $ONLINECLIENTINFOCONF
printf "%-35s" "name" >> $ONLINECLIENTINFOCONF
printf "%-6s\n" "ifhost" >> $ONLINECLIENTINFOCONF
kf_get_all_client_info(){
    allClientList=`cat /proc/net/arp`
    echo $allClientList
}
kf_get_ipaddr(){
    ipaddr=`uci get network.lan.ipaddr | cut -d . -f 1,2,3`
    echo $ipaddr
}
kf_get_online_client_mac_list(){
    ipaddr=`kf_get_ipaddr`
    onlineClientMacList=`cat /proc/net/arp  | grep $ipaddr | awk '{if($3=="0x2") print $4}'`    
    echo $onlineClientMacList
}
kf_get_client_ip_via_mac(){
    mac=$1
    clientip=`cat /proc/net/arp | grep $mac | awk '{print $1}'`
    echo $clientip
}
kf_get_client_name_via_mac(){
    mac=$1
    clientName=`cat /tmp/dhcp.leases | grep $mac | awk '{print $4}'`
    if [  "$clientName" == "" ] || [  "$clientName" == "*" ];then
        clientName="unknow"
    fi
    echo $clientName
}
kf_get_host_ip(){
    hostip=`netstat -anpt | grep uhttpd | awk ' {if($6=="ESTABLISHED") print $5} ' | awk '{if(NR==1) print $1}'| cut -d : -f 1`
    echo $hostip
}
#1 mean this host is setting router via web page now
kf_set_ifhost_flag_vai_ip(){
    clientip=$1
    hostip=`kf_get_host_ip`
    ifhost="0"
    if [ "$clientip" == "$hostip" ];then
        ifhost="1"
    fi
    echo $ifhost
}

onlineMacList=`kf_get_online_client_mac_list`
for mac in $onlineMacList; do
    clientip=`kf_get_client_ip_via_mac $mac`
    clientName=` kf_get_client_name_via_mac $mac`
    ifhost=`kf_set_ifhost_flag_vai_ip $clientip`
    printf "%-19s%-17s%-35s%-6d\n" "$mac" "$clientip" "$clientName" "$ifhost" >> $ONLINECLIENTINFOCONF
    #printf "%s" "$mac"
    #printf "%s" "$clientip"
    #printf "%s" "$clientName"

done
cat $ONLINECLIENTINFOCONF
