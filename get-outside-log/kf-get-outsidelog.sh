#Author:zhangtao@melinkr.com
#Date:2016年12月26日16:01:45
#Function:This script is used to get outsidelog from alllog
#!/bin/bash
#set -x
KF3_MAC_LIST_FILE_PATH="/root/files/for-vip/"
WORK_DIR="/root/files/for-vip"
LOG_DIR="/root/kflogs"
LAST_LOG_FILE_NAME_FILE_PATH="$WORK_DIR/shell/get-outside-log/last-log.conf"
LOG_FILE_PATH="/$WORK_DIR/shell/get-outside-log/result.log"
KF3_MAC_LIST=`ls -lh $WORK_DIR | grep -oE '[0-9]{1,2}M_vip_\w{12}_\w+' | grep -oE '[0-9A-Za-z]{12}'`
kf_get_latest_log_file_name(){
    local mac=$1
	local logFileName=`ls -lt /root/kflogs/$mac | grep -oE 'kflogs-[0-9A-Za-z]{12}-file-[0-9]{10}\.log' | head -n 1`
	echo $logFileName
}
kf_get_last_log_file_name(){
    local mac=$1
	cat $LAST_LOG_FILE_NAME_FILE_PATH | grep $mac > /dev/null
	if [  $? = 0 ];then
		local lastLogFileName=`cat $LAST_LOG_FILE_NAME_FILE_PATH | grep $mac| grep -oE 'kflogs-[0-9A-Za-z]{12}-file-[0-9]{10}\.log'`
	else
		local lastLogFileName="null"
	fi
	echo $lastLogFileName
}
kf_get_outside_network_log(){
    local logFileName=$1
	local mac=$2
	local currentTime=`date "+%y-%m-%d-%H%M%S"`
	rm -f $LOG_DIR/$mac/latest-outside-check*
	[ -f $LOG_DIR/$mac/$logFileName ] && cat $LOG_DIR/$mac/$logFileName | grep -E '\[www' > $LOG_DIR/$mac/latest-outside-check-$currentTime.log
}
while true;do
    echo "" > $LOG_FILE_PATH
    for mac in $KF3_MAC_LIST;do
        echo "start to deal with $mac" >> $LOG_FILE_PATH 
        currentLogFileName=`kf_get_last_log_file_name $mac` 
        latestLogFileName=`kf_get_latest_log_file_name $mac`
        if [ "$currentLogFileName" != "$latestLogFileName" ];then
    		echo "latest log file hase changed,start to refresh" >> $LOG_FILE_PATH
            #latest log has changed
            cat $LAST_LOG_FILE_NAME_FILE_PATH | grep $mac > /dev/null
            if [ $? = 0 ];then
         	   #mac alreaady exist 
         	   sed -i "/$mac/d"  $LAST_LOG_FILE_NAME_FILE_PATH
         	   echo -e "$mac $latestLogFileName" >> $LAST_LOG_FILE_NAME_FILE_PATH
         	   kf_get_outside_network_log $latestLogFileName $mac
            else
            #mac not exist
         	   echo -e "$mac $latestLogFileName" >> $LAST_LOG_FILE_NAME_FILE_PATH
         	   kf_get_outside_network_log $latestLogFileName $mac
            fi
    	else
    		echo "latest log file hase  not changed, do nothing" >> $LOG_FILE_PATH
        fi
	done
    sleep 100
done
