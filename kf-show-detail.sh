#Author:zhangtao@melinkr.com
#date:2016年11月9日11:05:47
#Function:This shell is used to show each mac info ,include vps port,vps ip,vps bandwith
#!/bin/sh
MAC_FILTER=$1
#set -x
RESULT_FILE_PATH="/root/files/for-vip/detail"
LIST_5M_FILE_PATH="/root/files/for-vip/5mlist"
LIST_10M_FILE_PATH="/root/files/for-vip/10mlist"
LIST_20M_FILE_PATH="/root/files/for-vip/20mlist"
LIST_UNKNOW_FILE_PATH="/root/files/for-vip/unknowlist"
cd /root/files/for-vip
MAC_LIST=`ls -l 40a5* | awk '{print $9}'`
count=1
echo "" > $RESULT_FILE_PATH
for line in $MAC_LIST; do
	mac=$line
    note=`ls -l *$line* | grep M | awk '{print $9}' | awk -F_ '{print $1}'`
	port=`cat ./$line | grep \"server_port\" | grep -oE '[0-9]{1,5}'| sed '/[0-9]\+/{N;s/\n/,/g}' |sed '/[0-9]\+/{N;s/\n/,/g}'`
	ipaddr=`cat ./$line | grep \"server\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sed '/[0-9]\+/{N;s/\n/,/g}' |sed '/[0-9]\+/{N;s/\n/,/g}'`
    #printf "%-5s" "|$count" >> $RESULT_FILE_PATH
    printf "%-14s" "|$mac" >> $RESULT_FILE_PATH
    printf "%-6s" "|$note" >> $RESULT_FILE_PATH
    printf "%-50s" "|$ipaddr" >> $RESULT_FILE_PATH
    printf "%-16s" "|$port " >> $RESULT_FILE_PATH
    printf  "|" >> $RESULT_FILE_PATH
	echo -e "" >> $RESULT_FILE_PATH
done
LIST_5M=` grep 5M ${RESULT_FILE_PATH} `
LIST_10M=` cat ${RESULT_FILE_PATH}  | grep 10M`
LIST_20M=` cat ${RESULT_FILE_PATH}  | grep 20M`
LIST_UNKNOW=`cat $RESULT_FILE_PATH |awk -F \| '$3=="     " {print $0}'`
echo -e "$LIST_5M" > $LIST_5M_FILE_PATH
echo -e "$LIST_10M" > $LIST_10M_FILE_PATH
echo -e "$LIST_20M" > $LIST_20M_FILE_PATH
echo -e "$LIST_UNKNOW" > $LIST_UNKNOW_FILE_PATH
echo "+----+-------------+-----+-------------------------------------------------+---------------+" > $RESULT_FILE_PATH
printf "%-5s" "|num" >> $RESULT_FILE_PATH
printf "%-14s" "|mac" >> $RESULT_FILE_PATH
printf "%-6s" "|note" >> $RESULT_FILE_PATH
printf "%-50s" "|ip" >> $RESULT_FILE_PATH
printf "%-16s" "|port" >> $RESULT_FILE_PATH
printf "|" >> $RESULT_FILE_PATH
echo -e "\n+----+-------------+-----+-------------------------------------------------+---------------+" >> $RESULT_FILE_PATH
while read line 
do
    printf "%-5s" "|$count" >> $RESULT_FILE_PATH
	echo -e "$line" >> $RESULT_FILE_PATH
    echo -e "+------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
	let count+=1
done < $LIST_5M_FILE_PATH
while read line 
do
    printf "%-5s" "|$count" >> $RESULT_FILE_PATH
	echo -e "$line" >> $RESULT_FILE_PATH
    echo -e "+------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
	let count+=1
done < $LIST_10M_FILE_PATH
while read line 
do
    printf "%-5s" "|$count" >> $RESULT_FILE_PATH
	echo -e "$line" >> $RESULT_FILE_PATH
    echo -e "+------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
	let count+=1
done < $LIST_20M_FILE_PATH
while read line 
do
    printf "%-5s" "|$count" >> $RESULT_FILE_PATH
	echo -e "$line" >> $RESULT_FILE_PATH
	let count+=1
    echo -e "+------------------------------------------------------------------------------------------+" >> $RESULT_FILE_PATH
done < $LIST_UNKNOW_FILE_PATH
cat $RESULT_FILE_PATH
rm -f $RESULT_FILE_PATH $LIST_5M_FILE_PATH $LIST_10M_FILE_PATH $LIST_20M_FILE_PATH $LIST_UNKNOW_FILE_PATH
