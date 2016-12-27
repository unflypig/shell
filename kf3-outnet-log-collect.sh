#/bin/bash
set -x
SERVER_IP="114.215.138.229"
MAC_NAME_FILE_REMOTE_PATH="/root/files/for-vip/shell/get-outside-log/mac-name.conf"
MAC_NAME_FILE_LOCAL_PATH="./mac-name.conf"
MECLOUD_DIR="/d/work/Mecloud同步盘/KF3监控数据"
LOG_REMOTE_FILE_PATH="/root/kflogs"
LOG_TMP="/d/work/kf3log-tmp"
[ -e $LOG_TMP ] || mkdir -p $LOG_TMP
scp root@$SERVER_IP:$MAC_NAME_FILE_REMOTE_PATH ./
kf-get-name-via-mac(){
    local mac=$1
    local name=`cat $MAC_NAME_FILE_LOCAL_PATH | grep $mac | awk -F: '{print $2}'`
    echo $name    
}
kf-get-log-file-via-mac(){
    mac=$1
    [ -e $LOG_TMP/$mac/ ] || mkdir -p $LOG_TMP/$mac/
    rm -f $LOG_TMP/$mac/*
    scp  root@$SERVER_IP:$LOG_REMOTE_FILE_PATH/$mac/latest-outside-check* $LOG_TMP/$mac/
}
kf-compare-md5-with-2-file(){
    filePath1=$1
    filePath2=$2
    local md5_value1=`md5sum $filePath1 | awk '{print $1}'`
    local md5_value2=`md5sum $filePath2 | awk '{print $1}'`
    if [ $md5_value1 = $md5_value2 ];then
        echo 0
    else
        echo 1
    fi
}
kf-get-latest-log-file-name-via-mac(){
    local mac=$1
    local name=$2
    [ -e $MECLOUD_DIR/$name/$mac ] || mkdir -p $MECLOUD_DIR/$name/$mac
    ls -lt  $MECLOUD_DIR/$name/$mac | grep -oE 'latest-outside-check.+' 
    if [ $? != 0 ];then
            echo "null"
    else
        local latestLogFileName=`ls -lt  $MECLOUD_DIR/$name/$mac | grep -oE 'latest-outside-check.+' | head -n 1`
        if [ $? != 0 ];then
            echo "null"
        else
            echo $latestLogFileName
        fi
    fi
    #sleep 50
}
KF3_MAC_LIST=`cat $MAC_NAME_FILE_LOCAL_PATH|awk -F: '{print $1}'`
KF3_NAME_LIST=`cat $MAC_NAME_FILE_LOCAL_PATH| awk -F: '{print $2}'`
for name in $KF3_NAME_LIST;do
    [ -e $MECLOUD_DIR/$name ] || mkdir  $MECLOUD_DIR/$name
done
for mac in $KF3_MAC_LIST;do
   echo "start to deal with $mac"
   kf-get-log-file-via-mac $mac
   name=`kf-get-name-via-mac $mac`
   LatestLogFileName=`kf-get-latest-log-file-name-via-mac $mac $name`
   LatestLogFileName=`echo -e "$LatestLogFileName" | head -n 1`
   if [ $LatestLogFileName != "null" ];then
       echo "get latest log file name success![$LatestLogFileName]"
       ret=`kf-compare-md5-with-2-file $LOG_TMP/$mac/latest-outside-check* $MECLOUD_DIR/$name/$mac/$LatestLogFileName`
       if [ $ret = 1 ];then
           echo "log file md5 have changed,start to refresh file"
           mv $LOG_TMP/$mac/latest-outside-check*  $MECLOUD_DIR/$name/$mac/
       else
           echo "log file md5 have not changed,do nothing"
       fi
   else
       echo "no latest log file exist"
       mv $LOG_TMP/$mac/latest-outside-check*  $MECLOUD_DIR/$name/$mac/
   fi
done
