#Author:zhangtao@melinkr.com
#Data:2016年12月29日10:25:26
#Function:This script is used to get if this server is useable by ping
#!/bin/bash
#set -x
WORK_DIR="/root/files/for-vip/test"
LOG_FILT_PATH="$WORK_DIR/kf-remove-disable-server.log"
KF3_MAC_LIST=`ls -lh $WORK_DIR | grep -oE '[0-9]{1,2}M_vip_\w{12}_\w+' \
    | grep -oE '[0-9A-Za-z]{12}'`
#this function will get if server is enable or not 
#input args is baund width
kf_get_server_enable_and_disable_list_via_bw(){
	local bandwidth=$1
    server_list=`cat ${WORK_DIR}/${bandwidth}m_vps.list`
    for server_ip in $server_list 
    do
    	#echo "start to deal with $server_ip"
	    local retry=3	
		local ip_access="false"
	    until [ $retry -lt 1 ]
		do
		    echo -e "Start to ping $server_ip"
    	    ping $server_ip -c 1 -w 3 > /dev/null
			if [ $? = 0 ];then
				ip_access="true"
				break
			else
			    retry=`expr $retry - 1`
			fi
		done
    	if [ $ip_access = "true" ];then
    		#echo "$server_ip:1" >> $SERVER_ENABLE_CONF_FILE_PATH
            local server_enable_list="${server_enable_list}${server_ip}:1\n"
    	else
    		#echo "$server_ip:0" >> $SERVER_ENABLE_CONF_FILE_PATH
            local server_enable_list="${server_enable_list}${server_ip}:0\n"
    	fi
    done
	echo -e "$server_enable_list"
    #sleep 50
}

kf_get_conf_info_via_mac(){
    local CONF_FILE_PATH="$WORK_DIR/shell/allmac.conf"
    [ -f $CONF_FILE_PATH ] || touch $CONF_FILE_PATH
	for mac in $KF3_MAC_LIST ;do
	    local confPath="$WORK_DIR/$mac"
	    local confContent="$mac:"
	    local confLines=`cat $confPath | wc -l`
	    confLines=`expr $confLines / 8`
	    local head=8
	    local end=8
        until [ $confLines -lt 1 ]
	    do
	    	local port=`cat $confPath | head -n $head|tail -n $end|\
			    grep server_port | grep -oE ":[0-9]{4,5}," | grep -oE "[0-9]+"`
	    	local server=`cat $confPath | head -n $head|tail -n $end\
			    |grep "\"server\"" | grep -oE "\"([0-9]{1,3}\.){3}[0-9]{1,3}\"" \
				    | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"`
	    	confContent="${confContent}${server}:${port}:"
	    	confLines=`expr $confLines - 1`
	    	head=`expr $head + 8`
	    done
        cat $CONF_FILE_PATH | grep $mac > /dev/null
	    if [ $? = 0 ];then
	        sed -i "/$mac/c\\$confContent" $CONF_FILE_PATH > /dev/null
	    else
	    	echo -e "$confContent" >> $CONF_FILE_PATH
	    fi
    done
	echo -e "`cat $CONF_FILE_PATH`"
}
#get server
#This function is used to get all server use detail include witch port be used and how many port be used 
kf_get_server_use_info_via_bw(){
	local bandwidth=$1
	local all_kf3_use_detal=`kf_get_conf_info_via_mac`
	local server_list=`cat ${WORK_DIR}/${bandwidth}m_vps.list`
    local SERVER_USE_DETAIL_CONF_FILE_PATH="$WORK_DIR/shell/${bandwidth}m_server_use_detail"
	rm -f $SERVER_USE_DETAIL_CONF_FILE_PATH
	for server_ip in $server_list 
	do
	   local server_use_port_info=`echo -e "$all_kf3_use_detal" |  grep $server_ip | grep -oE ":$server_ip:[0-9]{4,5}:" | grep -oE ":[0-9]{4,5}:"| sed s/://g|sort -n`
	   local server_use_info="$server_ip:"
	   for port in $server_use_port_info
	   do
           local server_use_info="${server_use_info}${port}:"
	   done
	   echo -e "$server_use_info" >> $SERVER_USE_DETAIL_CONF_FILE_PATH
	   #sleep 50
	done
	echo -e "`cat $SERVER_USE_DETAIL_CONF_FILE_PATH`"
}
kf_get_server_disable_list_via_bw(){
    local bandwidth=$1	
	local disable_and_enable_ip_list=`kf_get_server_enable_and_disable_list_via_bw $bandwidth`
	local disable_ip_list=`echo -e "$disable_and_enable_ip_list"\
	    | grep -oE ".+:0"| grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}"`
	echo -e "$disable_ip_list"
}
#Tihs function is used to get the best server
kf_get_best_server_via_bw(){
	local ip_port_nums_file_tmp="./ip_port_nums_file"
    local bandwidth=$1    
	local server_used_detail=`kf_get_server_use_info_via_bw $bandwidth`
	local server_ip_list=`echo -e "$server_used_detail" \
	    | grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}:" | sed "s/://g"`
	local ip_port_nums=""
	for ip in $server_ip_list
	do
		ping $ip -c 1 -w 2 > /dev/null 
		if [ $? = 0 ];then
		    local ip_port_nums="$ip:`echo -e \"$server_used_detail\"\
		        | grep $ip |grep -oE \"[0-9]{4,5}:\" | wc -l`"
		    echo -e "$ip_port_nums" >> $ip_port_nums_file_tmp
		fi
	done
	local ip_port_nums_all=`cat $ip_port_nums_file_tmp`
	rm -f $ip_port_nums_file_tmp
    #we need at least 4 ip,in case one of ip has already be used in conf file
	local best_ip=`echo -e "$ip_port_nums_all" |sort -n -t : -k 2 | head -n 4`
	echo -e "$best_ip"
}
#This function is used to get which port has been used via ip 
kf_get_used_port_via_ip(){
	local ip=$1
	for bw in 5 10 20 
	do
		kf_get_server_use_info_via_bw $bw | grep $ip > /dev/null
		if [ $? = 0 ];then
			#echo -e "`kf_get_server_use_info_via_bw $bw | grep $ip`"
			echo -e "`kf_get_server_use_info_via_bw $bw | grep $ip \
			    | grep -oE \"[0-9]{4,5}:\" | sed 's/://g'`"
			break
		fi
	done
}
kf_get_best_port_via_ip(){
    local ip=$1
	local port_start=9001
	local port_limit=20
	local port_end=`expr $port_start + $port_limit`
	local port=$port_start
	local used_port=`kf_get_used_port_via_ip $ip`
	local CONTINUE="yes"
	until [ $CONTINUE = "no" ]
	do
		echo -e "$used_port" | grep $port > /dev/null
		if [ $? != 0 ];then
			local CONTINUE="no"
			echo -e "$port"
			break
		else
		    local port=`expr $port + 1`
			if [ $port -gt $port_end ];then
				echo ">>>>ERROR:[${ip}] NO MORE PORT CAN BE USED!!!!<<<<"
				break
			fi
		fi
	done
}
kf_get_baundwhith_via_mac(){
    local mac=$1
    #local baundwhith=`ls -l ${WORK_DIR}/*$mac* | grep M | awk '{print $9}' | awk -F_ '{print $1}'` 	
    local baundwhith=`ls -l ${WORK_DIR}/*$mac* | grep -oE "[0-9]{1,2}M_vip"|grep -oE "[0-9]{1,2}"`
    echo -e "$baundwhith"
}
kf_get_passwd_via_port(){
    local port=$1
	local PASSWD_FILE_PATH="$WORK_DIR/pass"
	local passwd=`cat $PASSWD_FILE_PATH | grep \"$port\" | awk -F: '{print $2}'|grep -oE '\"\w+\"'`
	echo $passwd
}
kf_change_disable_server(){
    local mac=$1;local origin_ip=$2;local new_port=$3
	local new_ip=$4;local new_passwd=$5
	local conf_file_path="$WORK_DIR/$mac"
	local confLines=`cat $conf_file_path | wc -l`
	local confLines=`expr $confLines / 8`
	local head=8;local end=8
	local tmp_file="./tmp.conf"
	local conf_content_all_file="./tmp.all.conf"
    until [ $confLines -lt 1 ]
	do
		cat $conf_file_path | head -n $head|tail -n $end > $tmp_file
	    cat $tmp_file | grep $origin_ip > /dev/null
		if [ $? = 0 ];then
			local new_server_str="    \"server\":\"$new_ip\","
			local new_port_str="    \"server_port\":$new_port,"
			local new_passwd_str="    \"password\":\"$new_passwd\""
			sed -i "/$origin_ip/c\\$new_server_str" $tmp_file
			sed -i "/server_port/c\\$new_port_str" $tmp_file
			sed -i "/password/c\\$new_passwd_str" $tmp_file
			local conf_content=`cat $tmp_file`
		else
			local conf_content=`cat $tmp_file`
		fi
		echo -e "$conf_content" >> $conf_content_all_file
		confLines=`expr $confLines - 1`
		head=`expr $head + 8`
	done
	echo -e "`cat $conf_content_all_file`"
    cat $conf_content_all_file > $conf_file_path
	rm -f $tmp_file
	rm -rf $conf_content_all_file
}
kf_main(){
	local mac_use_server_detail=`kf_get_conf_info_via_mac`
	echo -e "################################mac use server detail#####################"
	#echo -e "################################mac use server detail#####################" >> $LOG_FILT_PATH
	echo -e "$mac_use_server_detail"
	#echo -e "$mac_use_server_detail" >> $LOG_FILT_PATH
	echo -e "##########################################################################"
	#echo -e "##########################################################################" >> $LOG_FILT_PATH
	for bw in  5 10 20 
	do
        #step 1:get disable server ip list
	    local disable_server_ip_list=`kf_get_server_disable_list_via_bw $bw`
		if [ -z $disable_server_ip_list ];then
		   echo -e "INFO:No Disable IP be Used in ${bw}M device, Try Next Bandwidth!"	
		   echo -e "INFO:No Disable IP be Used in ${bw}M device, Try Next Bandwidth!"	 >> $LOG_FILT_PATH
		   continue
	    fi
	    echo -e "############################disable ip list ###########################"
	    echo -e "############################disable ip list ###########################" >> $LOG_FILT_PATH
        echo -e "$disable_server_ip_list"		
        echo -e "$disable_server_ip_list" >> $LOG_FILT_PATH	
	    echo -e "#######################################################################"
	    echo -e "#######################################################################" >> $LOG_FILT_PATH
		for ip in $disable_server_ip_list 
		do
			local disable_ip=$ip
			echo -e "INFO:Start to Deal With Disable IP:[$disable_ip]"
			echo -e "INFO:Start to Deal With Disable IP:[$disable_ip]" >> $LOG_FILT_PATH
			#step 2:get mac list who has used disable ip
			local mac_who_use_disable_ip_list=`echo -e "$mac_use_server_detail" \
			    | grep $disable_ip|grep -oE "^[0-9A-Za-z]{12}"`
			if [  "$mac_who_use_disable_ip_list" ];then
			    echo -e "#######################use disable ip mac list#####################"
			    echo -e "#######################use disable ip mac list#####################" >> $LOG_FILT_PATH
                echo -e "$mac_who_use_disable_ip_list"
                echo -e "$mac_who_use_disable_ip_list" >> $LOG_FILT_PATH
			    echo -e "###################################################################"
			    echo -e "###################################################################" >> $LOG_FILT_PATH
			    for mac in $mac_who_use_disable_ip_list
			    do
			    	echo -e "INFO:Start to Deal whith MAC:[$mac]"
			    	echo -e "INFO:Start to Deal whith MAC:[$mac]" >> $LOG_FILT_PATH
                    #step 3:get baundwhith via mac
                    local bandwidth=`kf_get_baundwhith_via_mac $mac`
			    	echo -e "INFO:The Bandwidth of $mac is $bandwidth"
			    	echo -e "INFO:The Bandwidth of $mac is $bandwidth" >> $LOG_FILT_PATH
			    	local conf_file="$WORK_DIR/$mac"
			    	if [ -z $bandwidth ];then
			    		echo "ERROR:Get Baundwhith Via MAC Fail [$mac]"
			    		echo "ERROR:Get Baundwhith Via MAC Fail [$mac]" >> $LOG_FILT_PATH
						continue
			    	fi
                    #step 4:get best server via bandwidth
			    	local best_server_list=`kf_get_best_server_via_bw $bandwidth`
			    	echo -e "INFO:Best Server List:\n$best_server_list"
			    	echo -e "INFO:Best Server List:\n$best_server_list" >> $LOG_FILT_PATH
                    #step 5:check if which ip is not use in this conf file 
                    for ip in $best_server_list
			    	do
			    		local ip_format=`echo -e $ip \
			    		    | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}"`
			    		echo -e "INFO:Start to try $ip_format"
			    		echo -e "INFO:Start to try $ip_format" >> $LOG_FILT_PATH
			    		cat $conf_file | grep $ip_format > /dev/null
                        #this ip has not used in this conf file .we can go on ,or,we should use next ip 
			    		if [ $? != 0 ];then
                           local best_port=`kf_get_best_port_via_ip $ip_format` 
			    		   local passwd=`kf_get_passwd_via_port $best_port`
                           kf_change_disable_server $mac $disable_ip $best_port $ip_format $passwd > /dev/null
			    		   echo "INFO:Remove Disable IP:$ip_format from $mac Config File Success!"
			    		   echo "INFO:Remove Disable IP:$ip_format from $mac Config File Success!" >> $LOG_FILT_PATH
			    		   echo "INFO:New Config File is:"
			    		   echo "INFO:New Config File is:" >> $LOG_FILT_PATH
			    		   echo -e "`cat $conf_file`"
			    		   echo -e "`cat $conf_file`" >> $LOG_FILT_PATH 
			    		   #exit
						   break
					    else
			    		    echo -e "WARNING:$ip_format Has Already be Used in Config File,Try Next"
			    		    echo -e "WARNING:$ip_format Has Already be Used in Config File,Try Next" >> $LOG_FILT_PATH
			    		fi
			    	done
			    done
			else
				echo -e "INFO:No MAC Use Disable ip [$disable_ip]"
				echo -e "INFO:No MAC Use Disable ip [$disable_ip]" >> $LOG_FILT_PATH
			fi
		done
	done
}
#kf_main
#kf_get_server_use_info_via_bw $1
#kf_get_best_server_via_bw $1
#kf_get_used_port_via_ip $1
#kf_get_best_port_via_ip $1
#kf_get_baundwhith_via_mac $1
#kf_get_passwd_via_port $1
#kf_change_disable_server $1 $2 $3 $4 $5
kf_get_server_enable_and_disable_list_via_bw $1
#kf_main
