#Author:zhangtao@melinkr.com
#date:2017年1月5日11:12:08
#Function:This shell is used to clean big file
#!/bin/sh
_1M="1000000"
_10M="10000000"
_100M="100000000"
_500M="500000000"
LOG_FILE_PATH="/root/logs/kf-clean-big-file.log"
#size is byte
file_list="/root/logs/host.access.log"
kf_clean_big_file(){
    local file_path=$1
	local limit_size=$2
	local keep_line=$3
	local current_size=`ls -l $file_path|awk '{print $5}'`
	if [ $current_size -gt $limit_size ];then
		echo "File size is more then $limit_size,clean it!" >> $LOG_FILE_PATH
		echo "File size is more then $limit_size,clean it!" > $file_path.tmp
		tail -n $keep_line $file_path >> $file_path.tmp
		cat $file_path.tmp > $file_path
	else
		echo "File size is less then $limit_size,do nothing!" >> $LOG_FILE_PATH
	fi
}
kf_clean_big_file $LOG_FILE_PATH $_10M 100
for file_path in $file_list
do
	echo "Start to check [$file_path]" >> $LOG_FILE_PATH
	kf_clean_big_file $file_path $_500M 20000
done
