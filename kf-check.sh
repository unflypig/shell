#!/bin/sh                                                                                                                                                                        
#echo hi                                                                                                                                                                         
#set -x                                                                                                                                                                          
LOG_FILE_PATH="/tmp/check.log"                                                                                                                                                   
while true ; do                                                                                                                                                                  
    cur_time=`date "+%y-%m-%d %H:%M:%S"`                                                                                 
    connect_num_all=`cat /proc/net/nf_conntrack|wc -l`                                                                   
    connect_num_es=`cat /proc/net/nf_conntrack|grep ES|wc -l`                                                            
    echo -e "[${cur_time}] connect num all: ${connect_num_all}" >> $LOG_FILE_PATH                                        
    echo -e "[${cur_time}] connect num es: ${connect_num_es}" >> $LOG_FILE_PATH                                          
    clients_num_all=`cat /proc/net/arp | grep 192.168.133 | grep 0x2|wc -l`                                              
    clients_num_ap=`cat /proc/net/arp | grep 192.168.133 | grep 0x2 |grep 00:b0 |wc -l`                                  
    printf "[${cur_time}] client num: all %10s          ap:%10s\n" "$clients_num_all" "$clients_num_ap" >> $LOG_FILE_PATH
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
    url=`ubus call network.interface.wan status | grep nexthop | grep -oE '([0-9]{1,3}.){3}.[0-9]{1,3}'`                                                                                      
    ping $url -c 2 -w 2 > /dev/null                                                                             
    if [ $? = 0 ];then                                                                                                       
        echo -e "[${cur_time}] ping $url success" >> $LOG_FILE_PATH                                                          
    else                                                                                                                     
        echo -e "[${cur_time}] ping $url fail" >> $LOG_FILE_PATH                                                             
    fi                                                                                                          
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ifconfig info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> $LOG_FILE_PATH             
    echo -e "`ifconfig | tail -n 18| head -n 8`" >> $LOG_FILE_PATH                                                           
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
