#Author:zhangtao@melinkr.com
#date:2016年11月11日17:56:45
#Function:This shell is used to set KF3 vps config 
#!/bin/bash
#set -x
WORK_DIR="/root/files/for-vip/"

SUPPORT="false"
kf_get_vps_group_list(){
    local BAND_WIDTH=`echo $1 | grep -oE '[0-9]{1,2}'`
	local BAND_WIDTH_SUPPORT=`ls -l ${WORK_DIR}*m_vps.list | awk '{print $9}' | grep -oE '[0-9]{1,2}'`
    local VPS_LIST_FILE_PATH="${WORK_DIR}${BAND_WIDTH}m_vps.list"
	#echo -e "$BAND_WIDTH"
	#echo -e "$BAND_WIDTH_SUPPORT"
	for line in ${BAND_WIDTH_SUPPORT}; do 
		if [ "${line}" = "${BAND_WIDTH}" ];then
			SUPPORT="true"
		fi
	done
	if [ "$SUPPORT" = "false" ];then  
        echo -e "This bandwidth is not be supported!"
		exit 0
	fi
	VPS_COUNTS=`cat $VPS_LIST_FILE_PATH | wc -l`
    read -p "Please Input How many vps you want to use:" counts
	while [ "$counts" -gt "$VPS_COUNTS" -o "$counts" = "" ] 
	do
		echo "There is only $VPS_COUNTS here, you can not input more than $VPS_COUNTS!"
        read -p "Please Input How many vps you want to use:" counts
	done
	while [ "$counts" != "1" -a "$counts" != "3" ]
	do
		read -p "We just support 1 and 3,Please retype:" counts
	done

	CHOOSE_VPS_COUNT=$counts
    GROUPS_NUM=`expr $VPS_COUNTS / $counts`
    GROUPS_NUM_COPY=$GROUPS_NUM
	local i=1
	head=1
	end=$counts
	while [ $GROUPS_NUM -gt 0 ]
	do
		local VPS_LIST=`cat ${VPS_LIST_FILE_PATH} | head -n ${end} | tail -n +${head}`
		echo "#############################################################################"
	    echo -e "GROUP $i:\n$VPS_LIST"	
		head=`expr $head + $counts `
		end=`expr $end + $counts`
	    GROUPS_NUM=`expr $GROUPS_NUM - 1 `
		let i+=1
	done
	echo "#############################################################################"
	read -p "Please Input which group you want to use:" choise
    while [ "$choise" -gt "$GROUPS_NUM_COPY" -o "$choise" = "" ]
	do
		if [ $GROUPS_NUM_COPY -gt 1 ]
		then
		    read -p "Please select from 1 to $GROUPS_NUM_COPY:" choise
		else
		    read -p "Please select 1:" choise
		fi
	done
	end=`expr $choise \* $counts`
	head=`expr $end - $counts + 1 `
	CHOOSE_VPS_LIST=`cat ${VPS_LIST_FILE_PATH} | head -n ${end} | tail -n +${head}`
	echo -e  "You choose GROUP $choise:\n$CHOOSE_VPS_LIST"
	read -p "Please Input Witch Port You Want to Use in VPS(like 9001 9012 9013):" choise
	CHOOSE_PORT=$choise
	case $CHOOSE_VPS_COUNT in
		1)
            kf_motify_ss_conf_1 $BAND_WIDTH  "$CHOOSE_PORT" $MAC $NOTE
		;;
		3)
            kf_motify_ss_conf_3 $BAND_WIDTH  "$CHOOSE_PORT" $MAC $NOTE
		;;
	esac
}

kf_get_vps_info_via_port(){
    port=$1
	PASSWD_FILE_PATH="/root/files/for-vip/pass"
	passwd=`cat $PASSWD_FILE_PATH | grep \"$port\" | awk -F: '{print $2}'|grep -oE '\"\w+\"'`
	echo $passwd
}
kf_motify_ss_conf_1(){
	local BAND=$1
	local PORT=$2
	local MAC=$3
	local NOTE=$4
	CONFIG_TEMPLATE_1="/root/files/for-vip/config_template_1.conf"
	passwd=`kf_get_vps_info_via_port $PORT`
	conf_detail=`sed  -e "s/\"server_port\":9003,/\"server_port\":$PORT,/g" -e "s/\"password\":\"Maft0ic7cyam9ib\"/\"password\":$passwd/g" -e "s/\"server\":\"47.90.67.206\",/\"server\":\"$CHOOSE_VPS_LIST\",/g" /root/files/for-vip/config_template_1.conf`
	CONF_NAME_NOTE="${BAND}M_vip_${MAC}_${PORT}"
	[ -f $WORK_DIR/*M_vip_${MAC}_* ] && rm -f /root/files/for-vip/*M_vip_${MAC}_*
	echo -e "$conf_detail" > /root/files/for-vip/${BAND}M_vip_${MAC}_${PORT}_[${NOTE}]
	echo -e "$conf_detail" > /root/files/for-vip/${MAC}
    echo    "#############################################################################"
	echo -e "Config success!Below is detail:\n$conf_detail"
    echo    "#############################################################################"
}
kf_motify_ss_conf_3(){
	local BAND=$1
	local PORT=$2
	local MAC=$3
	local NOTE=$4
	CONFIG_TEMPLATE_1="/root/files/for-vip/config_template_1.conf"
	PORT1=`echo $PORT | awk -F " " '{print $1}'`
	PORT2=`echo $PORT | awk -F " " '{print $2}'`
	PORT3=`echo $PORT | awk -F " " '{print $3}'`
	CHOOSE_VPS_1=`echo -e "$CHOOSE_VPS_LIST" | awk -F " " 'NR==1 {print $0}'`
	CHOOSE_VPS_2=`echo -e "$CHOOSE_VPS_LIST" | awk -F " " 'NR==2 {print $0}'`
	CHOOSE_VPS_3=`echo -e "$CHOOSE_VPS_LIST" | awk -F " " 'NR==3 {print $0}'`

	passwd=`kf_get_vps_info_via_port $PORT1`
	passwd=`echo $passwd | sed 's/ //g'`
    conf_detail1=`sed  -e "s/\"server_port\":9003,/\"server_port\":$PORT1,/g" -e \
	    "s/\"password\":\"Maft0ic7cyam9ib\"/\"password\":$passwd/g" -e \
		    "s/\"server\":\"47.90.67.206\",/\"server\":\"$CHOOSE_VPS_1\",/g"\
		       	$CONFIG_TEMPLATE_1`
	passwd=`kf_get_vps_info_via_port $PORT2`
	passwd=`echo $passwd | sed 's/ //g'`
    conf_detail2=`sed  -e "s/\"server_port\":9003,/\"server_port\":$PORT2,/g"\
       	-e "s/\"password\":\"Maft0ic7cyam9ib\"/\"password\":$passwd/g" -e \
		    "s/\"server\":\"47.90.67.206\",/\"server\":\"$CHOOSE_VPS_2\",/g" \
			    $CONFIG_TEMPLATE_1`
	passwd=`kf_get_vps_info_via_port $PORT3`
	passwd=`echo $passwd | sed 's/ //g'`
    conf_detail3=`sed  -e "s/\"server_port\":9003,/\"server_port\":$PORT3,/g" \
	    -e "s/\"password\":\"Maft0ic7cyam9ib\"/\"password\":$passwd/g" -e\
	       	"s/\"server\":\"47.90.67.206\",/\"server\":\"$CHOOSE_VPS_3\",/g" \
			    $CONFIG_TEMPLATE_1`
	conf_detailall=`echo -e "$conf_detail1\n$conf_detail2\n$conf_detail3"`
	CONF_NAME_NOTE="${BAND}M_vip_${MAC}_${PORT}"
	[ -f $WORK_DIR/*M_vip_${MAC}_* ] && rm -f /root/files/for-vip/*M_vip_${MAC}_*
	echo -e "$conf_detailall" > /root/files/for-vip/${BAND}M_vip_${MAC}_${PORT1}_${PORT2}_${PORT3}_[${NOTE}]
	echo -e "$conf_detailall" > /root/files/for-vip/${MAC}
    echo    "#############################################################################"
	echo -e "Config success!Below is detail:\n$conf_detailall"
    echo    "#############################################################################"
}
echo "#############################################################################"
echo "# This shell is used to hlep you to give config file to a new router        #"               
echo "# Email: zhangtao@melinkr.com                                               #"
echo "#                                                                           #"
echo "# Author:unflypig                                                           #"
echo "# date:2016年11月11日16:40:33                                               #"
echo "#############################################################################"
echo ""
read -p "Please Input MAC:" MAC
str=$MAC;typeset -l str;MAC=$str;
MAC_LOW=$(echo $MAC | tr '[A-Z]' '[a-z]');
MAC=$MAC_LOW
echo $MAC | grep -oE '[0-9a-f]{12}' > /dev/null;
if [ $? != 0 ];then
	echo "$MAC is not available! Please check!"
	exit 0
fi
read -p "Please Input Note for This Device(can be null):" NOTE
read -p "Please Input BandWidth of This Router:" band
kf_get_vps_group_list $band

