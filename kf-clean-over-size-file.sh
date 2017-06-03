#Author:zhangtao@melinkr.com
#Data:2017年05月27日13:52:28
#Function:This scrip is used to clean over size file
#配置文件格式
#/etc/config/filesizectl 
#/root/kflogs/outside.log:f:3000000
#/tmp/kflogs/:d:1000000
#!/bin/sh
CONFIG_PATH="/etc/config/filesizectl"
kf_get_file_list(){
    echo -e "`cat /etc/config/filesizectl |grep ":f:"|cut -d: -f1|tr '\n' ' '`"
}
kf_get_dir_list(){
    echo -e "`cat /etc/config/filesizectl |grep ":d:"|cut -d: -f1|tr '\n' ' '`"
}
kf_get_file_size_limit(){
    local filename="$1"
    echo "`cat /etc/config/filesizectl |grep "$filename:"|cut -d: -f3`"
}
#根据文件路径和文件大小限制处理文件
kf_deal_file(){
    local file_path="$1"
    local file_limit_size="`kf_get_file_size_limit $file_path`"
    local file_current_size="`ls -l $file_path |awk '{print $5}'`"
    if [ "$file_current_size" -gt "$file_limit_size" ];then
        local tmp_file="/tmp/file.tmp"
        local file_current_line="cat $file_path|wc -l"
        local keep_line="`expr $file_current_line / 2`"
        echo '>>>>>>>>>>>>>>>>>>>>>[`date "+%Y-%M-%d %H:%M:%S"`]<<<<<<<<<<<<<<<<<<<<<<<' > $tmp_file
        echo '>>>>>>>>>>>>>>>>>>>>>file is over size clean it<<<<<<<<<<<<<<<<<<<<<<<' >> $tmp_file
        tail -n $keep_line >> $tmp_file
        cp $tmp_file $file
        rm $tmp_file
    fi
}
kf_deal_dir(){
    local dir_list="$1"
    for dir in $dir_list;do
        #获取目录下所有文件列表
        local file_list="`ls -l $dir |awk '{print $9}'`"
        lcoal file_limit_size="`cat $CONFIG_PATH |grep $dir|cut -d: -f3`"
        for file in $file_list;do
            local file="$dir$file"
            kf_deal_file $file $file_limit_size
        done 
    done
}
kf_main(){
    local file_list="`kf_get_file_list`"
    local dir_list="`kf_get_dir_list`"
    for file in $file_list;do
        kf_deal_file $file 
        exit
    done
    kf_deal_dir $dir_list
}
kf_main
