#Author:zhangtao@melinkr.com
#Data:2016年12月29日10:25:26
#Function:This script is used to get if this server is useable by ping
#!/bin/bash
#set -x
WORK_DIR="/root/files/for-vip"
KF3_MAC_LIST=`ls -lh $WORK_DIR | grep -oE '[0-9]{1,2}M_vip_\w{12}_\w+' \
    | grep -oE '[0-9A-Za-z]{12}'`


#this function will get if server is enable or not 
#input args is baund width
kf_get_server_enable_and_disable_list_via_bw(){
	local baundwidth=$1
    server_list=`cat ${WORK_DIR}/${baundwidth}m_vps.list`
    for server_ip in $server_list 
    do
    	#echo "start to deal with $server_ip"
    	ping $server_ip -c 1 -w 2 > /dev/null
    	if [ $? = 0 ];then
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
	local baundwidth=$1
	local all_kf3_use_detal=`kf_get_conf_info_via_mac`
	local server_list=`cat ${WORK_DIR}/${baundwidth}m_vps.list`
    local SERVER_USE_DETAIL_CONF_FILE_PATH="$WORK_DIR/shell/${baundwidth}m_server_use_detail"
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
    local baundwidth=$1	
	local disable_and_enable_ip_list=`kf_get_server_enable_and_disable_list_via_bw $baundwidth`
	local disable_ip_list=`echo -e "$disable_and_enable_ip_list"\
	    | grep -oE ".+:0"| grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}"`
	echo -e "$disable_ip_list"
}
#Tihs function is used to get the best server
kf_get_best_server_via_bw(){
	local ip_port_nums_file_tmp="./ip_port_nums_file"
    local baundwidth=$1    
	local server_used_detail=`kf_get_server_use_info_via_bw $baundwidth`
	local server_ip_list=`echo -e "$server_used_detail" \
	    | grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}:" | sed "s/://g"`
	local ip_port_nums=""
	for ip in $server_ip_list
	do
		local ip_port_nums="$ip:`echo -e \"$server_used_detail\"\
		    | grep $ip |grep -oE \"[0-9]{4,5}:\" | wc -l`"
		echo -e "$ip_port_nums" >> $ip_port_nums_file_tmp
	done
	local ip_port_nums_all=`cat $ip_port_nums_file_tmp`
	rm -f $ip_port_nums_file_tmp
	local best_ip=`echo -e "$ip_port_nums_all" |sort -n -t : -k 2 | head -n 1`
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
	local conf_file_path="$WORK_DIR/test/$mac"
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
	rm -f $tmp_file
	rm -rf $conf_content_all_file
}
kf_main(){
	local mac_use_server_detail=`kf_get_conf_info_via_mac`
	for bw in  5 10 20 
	do
        #step 1:get disable server ip list
	    local disable_server_ip_list=`kf_get_server_disable_list_via_bw $bw`
		for ip in $disable_server_ip_list 
		do
			local mac_who_use_disable_ip_list=`echo -e "$mac_use_server_detail" \
			    | grep $ip|grep -oE "^[0-9A-Za-z]{12}"`
            echo -e "$mac_who_use_disable_ip_list"
			for mac in $mac_who_use_disable_ip_list
			do
			    local ss_conf_file="$WORK_DIR/$mac"

			done
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
kf_change_disable_server $1 $2 $3 $4 $5
