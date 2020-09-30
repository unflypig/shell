#!/bin/sh

#================================================================
#   Copyright (C) 2020 zhangtao. All rights reserved.
#   
#   文件名称：progress_watch.sh
#   创 建 者：zhangt
#   创建日期：2020年09月18日
#   描    述：the shell script to watch progress,
#           if progress down, restart it
#
#================================================================
CONFIG_FILE_PATH="/etc/config/progress_watch"
[ -e ${CONFIG_FILE_PATH} ] || {
    cat >${CONFIG_FILE_PATH}<<EOF
config progress zipgateway
    option name 'zipgateway' #the progress name you want to watch
    option start_cmd '/etc/init.d/zipgateway start' #how to start progress
EOF
    exit 0;
}
#uci_content="`uci show ${CONFIG_FILE_PATH}`"
progress_list="`uci show ${CONFIG_FILE_PATH}|\
    grep -oE 'progress_watch.*=progress'|\
        grep -oE '\.\w+='|sed 's/\.//g'|sed 's/=//g'`"
#echo -e "$progress_list"
[ ! "${progress_list}" ] || {
    for progress in ${progress_list}
    do
        echo "start to check progress:${progress}"
        cnt="`ps www|grep ${progress} |wc -l`"
        if [ $cnt -lt 2 ];then
            echo "progress ${progress} not alive, restart it!"
            start_cmd="`uci get ${CONFIG_FILE_PATH}.${progress}.start_cmd`"
            [ ! ${start_cmd} ] || $start_cmd
        else
            echo "progress ${progress} still alive, do nothing!"
        fi
    done
}
