#Author:zhangtao@melfkljnkr.com
#date:2016年11月9日11:05:47
#Function:This shell is used to show each mac info ,include vps port,vps ip,vps bandwith
#!/bin/sh
#set -x
WORK_DIR="/root/files/for-vip"
ONLINE_INFO_CONF_FILE_PATH="$WORK_DIR/online.conf"
cd $WORK_DIR
MAC_LIST=`ls -l 40a5* | awk '{print $9}'`
kf_get_onlien_status(){
	local mac=$1
	cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac > /dev/null
	if [ $? != 0 ];then
		echo 0
	else
		local online_status=`cat $ONLINE_INFO_CONF_FILE_PATH \
		    | grep $mac |awk -F "|" '{print $5}'`
		if [ "$online_status" = "1" ];then
			echo 1
		else
			echo 0
		fi
	fi
}
kf_get_online_time(){
    local mac=$1
	local online_time=`cat $ONLINE_INFO_CONF_FILE_PATH \
	    | grep $mac |awk -F "|" '{print $2}'`
	echo -e "$online_time"
}
kf_get_online_info(){
    local mac=$1
	local online_status=`kf_get_onlien_status $mac`
	local online_time=`kf_get_online_time $mac`
	tail -n 10000 /root/logs/host.access.log | grep $mac > /dev/null
	if [ $? = 0 ];then
	    local newest_report_time=`tail -n 10000 /root/logs/host.access.log \
	        | grep $mac | tail -n 1 | grep -oE "\[.+\]" \
	    	    | sed "s/[][]//g"|awk '{print $1}' |sed "s/\//-/g"`
	    if [ $online_status = 0 ];then
            cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac > /dev/null
	    	if [ $? = 0 ];then
	    	    sed -i "/$mac/c\\$mac|$newest_report_time|$newest_report_time||1" $ONLINE_INFO_CONF_FILE_PATH
	    	else
	    	    echo -e "$mac|$newest_report_time|$newest_report_time||1" >> $ONLINE_INFO_CONF_FILE_PATH
	    	fi
	    else
	    	local online_info_str="${mac}|${online_time}|${newest_report_time}||1"
	    	sed -i "/$mac/c\\$online_info_str" $ONLINE_INFO_CONF_FILE_PATH
	    fi
	else
		cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac > /dev/null
		if [ $? = 0 ];then
			local offline_time=`cat $ONLINE_INFO_CONF_FILE_PATH|grep $mac | awk -F "|" '{print $4}'`
			local online_time=`cat $ONLINE_INFO_CONF_FILE_PATH|grep $mac | awk -F "|" '{print $2}'`
			local last_update_time=`cat $ONLINE_INFO_CONF_FILE_PATH|grep $mac | awk -F "|" '{print $3}'`
			if [ $online_time ];then
				local offline_time_len=`echo $offline_time  | wc -c`
				if [ $offline_time_len -lt 5 ];then
		            local current_time=`date "+%y-%m-%d %H:%M:%S"`
		            local online_info_str="${mac}|${online_time}||$current_time|0"
			        sed -i "/$mac/c\\$online_info_str" $ONLINE_INFO_CONF_FILE_PATH
				else
				    echo "nothing to do,[$mac]" > /dev/null
				fi
			else
				echo "nothing to do,[$mac]" > /dev/null
			fi
		else
			local online_info_str="${mac}||||0"
			echo -e "$online_info_str" >> $ONLINE_INFO_CONF_FILE_PATH
		fi
	fi
}
for mac in $MAC_LIST;do
    kf_get_online_info $mac
done
