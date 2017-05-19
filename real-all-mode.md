- /etc/firewall.user
```
# This file is interpreted as shell script.
# Put your custom iptables rules here, they will
# be executed with each firewall (re-)start.

# Internal uci firewall chains are flushed and recreated on reload, so
# put custom rules into the root chains e.g. INPUT or FORWARD or into the
# special user chains, e.g. input_wan_rule or postrouting_lan_rule.
NO=1
NORMAL=2
ALL=3
KFCONFIG_FILE_PATH="/etc/kfconfig/kfconfig"
current_accelerate_mode=`uci get $KFCONFIG_FILE_PATH.vpn.mode`

#普通模式
if [ "$current_accelerate_mode" = "$NORMAL" ]
then
    ipset list gfwipset > /dev/null
    if [ $? != 0 ];then
        ipset creat selflist hash:net
    fi

    iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwipset dst -j REDIRECT --to-port 1080
    iptables -t nat -A OUTPUT -p tcp -m set --match-set gfwipset dst -j REDIRECT --to-port 1080
fi
#全局模式
if [ "$current_accelerate_mode" = "$ALL" ]
then
    #增加用于存放不走shadowsocks代理的ip集合
    ipset list inlist > /dev/null
    if [ $? != 0 ];then
        ipset creat inlist hash:net
    fi
    #以下三个IP段为局域网IP段，这部分IP打上inlist标记,不走本地shadowsocks代理
    ipset add inlist 192.168.0.0/16
    ipset add inlist 172.16.0.0/12
    ipset add inlist 10.0.0.0/8

    #增加用于存放本机OUTPUT链走shadowsocks代理的ip集合
    #selflist中仅存放由于外网连通性检测的网址，如google.com/facebook.com/us.kfrouter.com/等
    ipset list selflist > /dev/null
    if [ $? != 0 ];then
        ipset creat selflist hash:net
    fi

    #本条规则实现除了inlist 集合里的IP外，其他全部走本地shadowsocks代理,解决了之前使用ip就无法走代理的问题
    #inlist 集合中,均为局域网IP段,这部分IP不能走代理
    iptables -t nat -A PREROUTING -p tcp -m set ! --match-set inlist dst -j REDIRECT --to-port 1080
    #本条规则实现了路由器本机访问selflist集合中ip时走本地代理,解决了，本机无法访问外网问题，
    #selflist中仅存放由于外网连通性检测的网址，如google.com/facebook.com/us.kfrouter.com/等
    iptables -t nat -A OUTPUT -p tcp -m set  --match-set selflist dst -j REDIRECT --to-port 1080

fi
#唐路由模式
    $ALL_MODE)
        ipset list chinaiplist > /dev/null
        if [ "$?" != "0" ];then
            ipset creat chinaiplist hash:net
        fi
        ipset list serverlist > /dev/null
        if [ "$?" != "0" ];then
            ipset creat serverlist hash:net
        fi

        iptables -t nat -C PREROUTING -p tcp -m set  --match-set chinaiplist dst -j REDIRECT --to-port $ss_local_port
        if [ $? != 0 ];then
            iptables -t nat -I PREROUTING -p tcp -m set  --match-set chinaiplist dst -j REDIRECT --to-port $ss_local_port
        fi

        iptables -t nat -C PREROUTING -p tcp -m set  --match-set serverlist dst -j RETURN
        if [ $? != 0 ];then
            iptables -t nat -I PREROUTING -p tcp -m set  --match-set serverlist dst -j RETURN
        fi

        iptables -t nat -C OUTPUT -p tcp -m set  --match-set chinaiplist dst -j REDIRECT --to-port $ss_local_port
        if [ $? != 0 ];then
            iptables -t nat -I OUTPUT -p tcp -m set  --match-set chinaiplist dst -j REDIRECT --to-port $ss_local_port
        fi

        iptables -t nat -C OUTPUT -p tcp -m set  --match-set serverlist dst -j RETURN
        if [ $? != 0 ];then
            iptables -t nat -I OUTPUT -p tcp -m set  --match-set serverlist dst -j RETURN
        fi
        /tmp/kf/kf-add-cniplist-to-ipset.sh
        ;;

mode=`cat /etc/config/macfiltermode`
enable=`cat /etc/config/macfilterenable`
/bin/sh /tmp/kf/kfmac_filter.sh $enable $mode
/tmp/kf/kf-set-terminals-property.sh
```
- /etc/dnsmasq.d.all/dnsmasq-new.conf
```
server=/#/127.0.0.1#5300
```
- /etc/dnsmasq.d.all/kfrouter-new.conf
```
ipset=/.us.kfrouter.com/selflist
ipset=/.jp.kfrouter.com/selflist
ipset=/.sgp.kfrouter.com/selflist
ipset=/youtube.com/selflist
ipset=/facebook.com/selflist
ipset=/google.com/selflist
ipset=/twitter.com/selflist
ipset=/t.co/selflist
```
