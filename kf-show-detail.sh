#Author:zhangtao@melinkr.com
#date:2016年11月9日11:05:47
#Function:This shell is used to show each mac info ,include vps port,vps ip,vps bandwith
#!/bin/sh
#tail -n 10000 /root/logs/host.access.log | grep 40a5efe035d8 | tail -n 1 | grep -oE "\[.+\]" | sed "s/[][]//g"|awk '{print $1}'
MAC_FILTER=$1
#set -x
WORK_DIR="/root/files/for-vip"
RESULT_FILE_PATH="/root/files/for-vip/detail"
LIST_1M_FILE_PATH="/root/files/for-vip/1mlist"
LIST_5M_FILE_PATH="/root/files/for-vip/5mlist"
LIST_10M_FILE_PATH="/root/files/for-vip/10mlist"
LIST_20M_FILE_PATH="/root/files/for-vip/20mlist"
LIST_UNKNOW_FILE_PATH="/root/files/for-vip/unknowlist"
ONLINE_INFO_CONF_FILE_PATH="$WORK_DIR/online.conf"
/root/files/for-vip/shell/kf-update-online-info.sh
cd /root/files/for-vip
MAC_LIST=`ls -l 40a5* | awk '{print $9}'`
count=1
echo "" > $RESULT_FILE_PATH
for line in $MAC_LIST; do
	mac=$line
    bw=`ls -l *$line* | grep M | awk '{print $9}' | awk -F_ '{print $1}'`
	port=`cat ./$line | grep \"server_port\" | grep -oE '[0-9]{1,5}'| sed '/[0-9]\+/{N;s/\n/,/g}' |sed '/[0-9]\+/{N;s/\n/,/g}'`
	ipaddr=`cat ./$line | grep \"server\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed '/[0-9]\+/{N;s/\n/,/g}' |sed '/[0-9]\+/{N;s/\n/,/g}'`
	note=` ls -l *$line* | grep M |grep -oE "\[.+\]$" | sed -e "s/[][]//g"`
	online_time=`cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac | awk -F "|" '{print $2}' `
	last_update_time=`cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac | awk -F "|" '{print $3}' `
	offline_time=`cat $ONLINE_INFO_CONF_FILE_PATH | grep $mac | awk -F "|" '{print $4}' `
    #printf "%-5s" "|$count" >> $RESULT_FILE_PATH
    printf "%-14s" "|$mac" >> $RESULT_FILE_PATH
    printf "%-6s" "|$bw" >> $RESULT_FILE_PATH
    printf "%-45s" "|$ipaddr" >> $RESULT_FILE_PATH
    printf "%-16s" "|$port " >> $RESULT_FILE_PATH
	printf "%-22s" "|$online_time " >> $RESULT_FILE_PATH
	printf "%-22s" "|$last_update_time " >> $RESULT_FILE_PATH
	printf "%-22s" "|$offline_time " >> $RESULT_FILE_PATH
    printf "%-30s" "|$note" >> $RESULT_FILE_PATH
    printf  "|" >> $RESULT_FILE_PATH
	echo -e "" >> $RESULT_FILE_PATH
done
#LIST_1M=` grep -E "1M   " ${RESULT_FILE_PATH} `
#LIST_5M=` grep -E "5M   " ${RESULT_FILE_PATH} `
#LIST_10M=` cat ${RESULT_FILE_PATH}  | grep -E  "10M  "`
#LIST_20M=` cat ${RESULT_FILE_PATH}  | grep -E "20M  "`
LIST_1M=`cat $RESULT_FILE_PATH | awk -F "|" '{if($3=="1M   ") print $0}'`
LIST_5M=`cat $RESULT_FILE_PATH | awk -F "|" '{if($3=="5M   ") print $0}'`
LIST_10M=`cat $RESULT_FILE_PATH | awk -F "|" '{if($3=="10M  ") print $0}'`
LIST_20M=`cat $RESULT_FILE_PATH | awk -F "|" '{if($3=="20M  ") print $0}'`
LIST_UNKNOW=`cat $RESULT_FILE_PATH |awk -F \| '$3=="     " {print $0}'`
echo -e "$LIST_1M" > $LIST_1M_FILE_PATH
echo -e "$LIST_5M" > $LIST_5M_FILE_PATH
echo -e "$LIST_10M" > $LIST_10M_FILE_PATH
echo -e "$LIST_20M" > $LIST_20M_FILE_PATH
echo -e "$LIST_UNKNOW" > $LIST_UNKNOW_FILE_PATH
echo "+----+-------------+-----+-------------------------------------------------+---------------+------------------------------------------------------------------------------------------+" > $RESULT_FILE_PATH
printf "%-5s" "|num" >> $RESULT_FILE_PATH
printf "%-14s" "|mac" >> $RESULT_FILE_PATH
printf "%-6s" "|bw" >> $RESULT_FILE_PATH
printf "%-45s" "|ip" >> $RESULT_FILE_PATH
printf "%-16s" "|port" >> $RESULT_FILE_PATH
printf "%-22s" "|online_time" >> $RESULT_FILE_PATH
printf "%-22s" "|last_update_time" >> $RESULT_FILE_PATH
printf "%-22s" "|offline__time" >> $RESULT_FILE_PATH
printf "%-30s" "|note" >> $RESULT_FILE_PATH
printf "|" >> $RESULT_FILE_PATH
echo -e "\n+----+-------------+-----+-------------------------------------------------+---------------+------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
for bw in 1 5 10 20
do
	LIST_FILE_PATH="/root/files/for-vip/${bw}mlist"
    while read line 
    do
        printf "%-5s" "|$count" >> $RESULT_FILE_PATH
    	echo -e "$line" >> $RESULT_FILE_PATH
        echo -e "+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
    	let count+=1
    done < $LIST_FILE_PATH
done
cat $RESULT_FILE_PATH
rm -f $RESULT_FILE_PATH $LIST_1M_FILE_PATH  $LIST_5M_FILE_PATH $LIST_10M_FILE_PATH $LIST_20M_FILE_PATH $LIST_UNKNOW_FILE_PATH
