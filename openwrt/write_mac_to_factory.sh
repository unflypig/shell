#!/bin/sh

#================================================================
#   Copyright (C) 2020 zhangtao.com. All rights reserved.
#   
#   文件名称：reset_art_date.sh
#   创 建 者：zhangt
#   创建日期：2020年08月28日
#   描    述：将MAC地址信息写入到路由器对应分区中
#
#================================================================
ART_DEVICE_PATH="/dev/mtd5"
LOG_FILE="/tmp/reset_art_date.log"
WAN_OFFSET=0
WIFI0_OFFSET=4098
YES=1
NO=0
wan_mac=$1

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
write_wan_mac_date() {
    wan_mac=$1
    offset=$2
    wan_mac=`echo ${wan_mac} |sed s/://g`
    wan_mac0=${wan_mac:0:2};wan_mac1=${wan_mac:2:2}
    wan_mac2=${wan_mac:4:2};wan_mac3=${wan_mac:6:2}
    wan_mac4=${wan_mac:8:2};wan_mac5=${wan_mac:10:2}
    echo -e -n "\x${wan_mac0}\x${wan_mac1}\x${wan_mac2}\x${wan_mac3}\x${wan_mac4}\x${wan_mac5}" \
        |dd of=/tmp/art.bin  bs=1 count=6 conv=notrunc bs=1 count=6 seek=$offset
}
write_wifi0_mac_date() {
    wifi0_mac=$1
    offset=$2
    wifi0_mac=`echo ${wifi0_mac} |sed s/://g`
    wifi0_mac0=${wifi0_mac:0:2};wifi0_mac1=${wifi0_mac:2:2}
    wifi0_mac2=${wifi0_mac:4:2};wifi0_mac3=${wifi0_mac:6:2}
    wifi0_mac4=${wifi0_mac:8:2};wifi0_mac5=${wifi0_mac:10:2}
    echo -e -n "\x${wifi0_mac0}\x${wifi0_mac1}\x${wifi0_mac2}\x${wifi0_mac3}\x${wifi0_mac4}\x${wifi0_mac5}" \
        |dd of=/tmp/art.bin  bs=1 count=6 conv=notrunc bs=1 count=6 seek=$offset
}
#creat log file if not exist
[ -f $LOG_FILE ] || touch $LOG_FILE

#copy art date
dd if=${ART_DEVICE_PATH} of=/tmp/art.bin
ret=`is_macaddr_valid $wan_mac`
if [ $ret -eq $YES ];then
    #write wan mac date
    write_wan_mac_date $wan_mac $WAN_OFFSET
    #write wifi0 mac date
    wifi0_mac=`macaddr_increase $wan_mac 2`
    write_wifi0_mac_date $wifi0_mac $WIFI0_OFFSET
else
    echo "MAC:${wan_mac} is invalid!" >> $LOG_FILE
    exit
fi

#write date to art
mtd write /tmp/art.bin art
