#!/bin/sh
set -x
#================================================================
#   Copyright (C) 2020 zhangtao. All rights reserved.
#   
#   文件名称：mac.sh
#   创 建 者：zhangt
#   创建日期：2020年08月28日
#   描    述：This shell script is used to motify mac address for wan,lan,wifi0,wifi1(在QCA9563硬件平台上）
#
#================================================================
YES=1
NO=0
WAN_MAC_OFFSET=0
WIFI0_MAC_OFFSET=4098
WIFI1_MAC_OFFSET=20486
WAN_INTERFACE_NAME="eth0.2"
LAN_INTERFACE_NAME="br-lan"
#2.4G wifi
WIFI0_INTERFACE_NAME="wifi0"
#5G wifi
WIFI1_INTERFACE_NAME="wifi1"

set_wan_macaddr() {
    local mac=$1
    local is_macaddr_valid=`is_macaddr_valid $mac`
    if [ $is_macaddr_valid -eq $YES ];then
        local wan_mac=`get_interface_macaddr $WAN_INTERFACE_NAME`
    fi

}
set_lan_macaddr() {
    local mac=$1
    ifconfig $LAN_INTERFACE_NAME hw ether $mac
    ifconfig $LAN_INTERFACE_NAME down
    sleep 2
    ifconfig $LAN_INTERFACE_NAME up
}
#set_wifi0_macaddr() {}
set_wifi1_macaddr() {
    local mac=$1
    uci set wireless.wifi1.macaddr=$mac
    uci commit wireless
    wifi down
    sleep 2
    wifi up
}
get_interface_macaddr() {
    interface=$1
    macaddr=`cat /sys/class/net/$interface/address`
    echo $macaddr
}
#read_macaddr_from_art() {
#    interface=$1
#    if [ $interface -eq "wan" ];then
#        wan_mac=  
#    fi
#}
is_macaddr_valid() {
    macaddr=$1
    macaddr_len=`echo $macaddr |grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}'`
    if [ ${#macaddr_len} -eq 17 ];then
        echo $YES
    else
        echo $no
    fi
}
macaddr_increase() {
    hex_origion=$1
    increase_num=$2
    hex_mac=`echo 0x${hex_origion} |sed 's/://g'`
    shi_mac=`printf %d $hex_mac`
    shi_mac=`expr $shi_mac + $increase_num`
    local mac=`printf %x $shi_mac`
    echo "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
    #return "0x`printf %x $shi_mac`"
}
set_macaddr() {
    local wan_mac=`get_interface_macaddr $WAN_INTERFACE_NAME`
    iswan_mac_valid=`is_macaddr_valid $wan_mac`
    if [ $iswan_mac_valid -eq $YES ];then
        lan_macaddr=`macaddr_increase $wan_mac 1`
        wifi0_macaddr=`macaddr_increase $wan_mac 2`
        wifi1_macaddr=`macaddr_increase $wan_mac 3`
        set_lan_macaddr $lan_macaddr
        set_wifi1_macaddr $wifi1_macaddr
    fi
}

#macaddr_increase "ac:db:da:5b:6f:09" 1
#macaddr_increase "ac:db:da:5b:6f:09" 10
set_macaddr
