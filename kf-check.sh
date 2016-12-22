#!/bin/sh
#set -x
LOG_FILE_PATH="/tmp/check.log"
cnts=$#
if [ $cnts == 0 ];then
	apMac="no"
elif [ $cnts == 1 ];then
	apMac=$1
elif [ $cnts -gt 1 ];then
	echo "too many args!!"
	exit
fi
while true ; do
    cur_time=`date "+%y-%m-%d %H:%M:%S"`                                                                                 
    connect_num_all=`cat /proc/net/nf_conntrack|wc -l`                                                                   
    connect_num_es=`cat /proc/net/nf_conntrack|grep ES|wc -l`                                                            
    #echo -e "[${cur_time}] connect num all: ${connect_num_all}" >> $LOG_FILE_PATH                                        
    #echo -e "[${cur_time}] connect num es: ${connect_num_es}" >> $LOG_FILE_PATH                                          
    printf "[${cur_time}] connect num all: %-10d connect num es: %-10d\n" "${connect_num_all}" "${connect_num_es}" >> $LOG_FILE_PATH
	lanIp=`uci get network.lan.ipaddr | grep -oE '([0-9]{1,3}\.){2}[0-9]{1,3}'`
    clients_num_all=`cat /proc/net/arp | grep $lanIp | grep 0x2|wc -l`                                              
	if  [ $apMac = "no" ];then
		clients_num_ap=0
	else
        clients_num_ap=`cat /proc/net/arp | grep $lanIp | grep 0x2  | grep $apMac |wc -l`                                  
	fi
    printf "[${cur_time}] client num all:%-10s          ap:%-10s\n" "$clients_num_all" "$clients_num_ap" >> $LOG_FILE_PATH
    url="114.114.114.114"                                                                                                
    ping $url -c 2 -w 2 > /dev/null                                                                                      
    if [ $? = 0 ];then                                                                                                   
        echo -e "[${cur_time}] ping $url success" >> $LOG_FILE_PATH                                                      
    else                                                                                                                 
        echo -e "[${cur_time}] ping $url fail" >> $LOG_FILE_PATH                                                         
    fi                                                                                                                   
    url="baidu.com"                                                
    ping $url -c 2 -w 2 > /dev/null                                
    if [ $? = 0 ];then                                             
        echo -e "[${cur_time}] ping $url success" >> $LOG_FILE_PATH
    else                                                           
        echo -e "[${cur_time}] ping $url fail" >> $LOG_FILE_PATH   
    fi                                                             
    #gateway
    url=`ubus call network.interface.wan status | grep nexthop | grep -oE '([1-9]{1,3}.){3}[0-9]{1,3}'`                                                                                      
    ping $url -c 2 -w 2 > /dev/null                                                                             
    if [ $? = 0 ];then                                                                                                       
        echo -e "[${cur_time}] ping $url success" >> $LOG_FILE_PATH                                                          
    else                                                                                                                     
        echo -e "[${cur_time}] ping $url fail" >> $LOG_FILE_PATH                                                             
    fi                                                                                                          
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ifconfig info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH             
	line=`ifconfig | grep "eth0.2" -n | grep -oE '^[0-9]{1,3}'`
    echo -e "`ifconfig | head -n \`expr $line + 8\` | tail -n 10`" >> $LOG_FILE_PATH                                                           
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ps info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH             
    ps www >>  $LOG_FILE_PATH                                                                                             
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>top info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH             
    top -n 1 >> $LOG_FILE_PATH                                                                                               
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>cpu  info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH             
    cat /proc/cpuinfo >> $LOG_FILE_PATH                                                                                      
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>memery  info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH              
    cat /proc/meminfo >> $LOG_FILE_PATH                                                                                      
    sleep 180 
done                             
