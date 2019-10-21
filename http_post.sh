#!/bin/bash
set -x
#JV_API_DOMAIN "http://weixin.nvsip.com"
#JV_API_PORT 8813
time_strap=`date '+%F %T'`
JV_API_PORT=8080
JV_API_DOMAIN="http://172.20.8.32"
DEVICE_HEART_BEAT_API_URL="/upgrade/api/deviceHeartbeat/push"
DEVICE_UPGRADE_HEART_BEAT_API_URL="/upgrade/api/deviceUpgradeHeartbeat/push"
mac=100000000001
yst_id=800000000000
post_json="{\"method\":\"device\",\"mac\":\"${mac}\",\"deviceType\":\"H6CV500-S-20-L 0S77\",\"softVersionNo\":\"V2.2.5005 - 20191020 12:50:59\",\"cloudseeNo\":\"${yst_id}\",\"vendor\":\"jovision\",\"chnsum\":1,\"time\":\"${time_strap}\"}"
curl -v ${JV_API_DOMAIN}:${JV_API_PORT}${DEVICE_HEART_BEAT_API_URL} -X POST -H "Content-Type:application/json" -d "${post_json}"
count=0
while [ "$mac" -lt 100000000100 ];do
    #sleep 1;
    mac=`expr $mac + 1`
    yst_id=`expr $yst_id + 1`
    time_strap=`date '+%F %T'`
    post_json="{\"method\":\"device\",\"mac\":\"${mac}\",\"deviceType\":\"H6CV500-S-20-L 0S77\",\"softVersionNo\":\"V2.2.5005 - 20191020 12:50:59\",\"cloudseeNo\":\"${yst_id}\",\"vendor\":\"jovision\",\"chnsum\":1,\"time\":\"${time_strap}\"}"
    curl -v ${JV_API_DOMAIN}:${JV_API_PORT}${DEVICE_HEART_BEAT_API_URL} -X POST -H "Content-Type:application/json" -d "${post_json}" &
done
