#Author:zhangtao@melinkr.com
#Data:2017年4月17日14:04:34
#Function:This scrip is used to add public ip into ipset list
#!/bin/sh
vpn_mode="`uci get /etc/kfconfig/kfconfig.vpn.mode`"
if [ "$vpn_mode" = "3" ];then
    public_ip="`curl http://checkip.amazonaws.com/`"
    ipset list inlist|grep $public_ip -q
    if [ "$?" != 0 ];then
        ipset add inlist $public_ip
    fi
fi
