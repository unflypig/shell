#Author:zhangtao@melinkr.com
#Data:2017年05月27日13:52:28
#Function:This scrip is used to clean over size file
#!/bin/sh
CONFIG_PATH="/etc/config/filesizectl"
arg_num="$#"
#初始化配置文件，若文件不存在则写入默认值
kf_init_config_file(){
    [ -e "$CONFIG_PATH" ] || {
        echo -e "#path:file/dir:limitsize\n#1M = 1000000\n/root/kflogs/outside.log:f:3000000\n/tmp/kflogs/:d:1000000" > $CONFIG_PATH
    }
}
#获取配置文件中所有文件列表
kf_get_file_list(){
    echo -e "`cat /etc/config/filesizectl |grep ":f:"|cut -d: -f1|tr '\n' ' '`"
}
#获取配置文件中所有目录列表
kf_get_dir_list(){
    echo -e "`cat /etc/config/filesizectl |grep ":d:"|cut -d: -f1|tr '\n' ' '`"
}
#通过文件名称,获取该文件在配置文件中所设置的限制大小
kf_get_file_size_limit(){
    local filename="$1"
    echo "`cat /etc/config/filesizectl |grep "$filename:f:"|cut -d: -f3`"
}
#通过目录名称,获取该目录在配置文件中所设置的限制大小
kf_get_dir_size_limit(){
    local dir_name="$1"
    echo "`cat /etc/config/filesizectl |grep "$dir_name:d:"|cut -d: -f3`"
}
#根据文件路径和文件大小限制处理文件
kf_deal_file(){
    local file_path="$1"
    local file_limit_size="$2"
    #获取该文件当前大小
    local file_current_size="`ls -l $file_path |awk '{print $5}'`"
    #若该文件当前大小超过设置大小则处理
    if [ "$file_current_size" -gt "$file_limit_size" ];then
        #对于超过限制大小的文件，我们教文件的前半部分删除，只保留后半部分
        local tmp_file="/tmp/file.tmp"
        local file_current_line="`cat $file_path|wc -l`"
        local keep_line="`expr $file_current_line / 2`"
        local current_time="`date '+%Y-%M-%d %H:%M:%S'`"
        echo ">>>>>>>>>>>>>>>>>>>>>[$current_time]<<<<<<<<<<<<<<<<<<<<<<<" > $tmp_file
        echo '>>>>>>>>>>>>>>>>>>>>>file is over size, clean it<<<<<<<<<<<<<<<<<<<<<<<' >> $tmp_file
        tail -n $keep_line $file_path >> $tmp_file
        mv $tmp_file $file_path
    fi
}
#根据目录，处理该目录下所有的文件
kf_deal_dir(){
    local dir_list="$1"
    for dir in $dir_list;do
        #获取目录下所有文件列表
        local file_list="`ls -l $dir |awk '{print $9}'`"
        local file_limit_size="`cat $CONFIG_PATH |grep "$dir:d:"|cut -d: -f3`"
        for file in $file_list;do
            local file="$dir$file"
            kf_deal_file $file $file_limit_size
        done 
    done
}
kf_main(){
    kf_init_config_file
    local file_list="`kf_get_file_list`"
    local dir_list="`kf_get_dir_list`"
    for file in $file_list;do
        local file_limit_size="`kf_get_file_size_limit $file_path`"
        kf_deal_file $file $file_limit_size 
    done
    kf_deal_dir $dir_list
}
#若输入参数为非空则处理输入的文件名和文件大小
if [ "$arg_num" = "2" ];then
    file_name="$1"
    size_limit="$2"
    kf_deal_file $file_name $size_limit
#若输入参数为空则处理配置文件中的文件
else
    kf_main
fi
