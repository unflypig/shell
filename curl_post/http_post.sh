#!/bin/bash
set -x
time_strap=`date '+%F %T'`
#JV_API_PORT=8080
#JV_API_DOMAIN="http://172.20.8.32"
DEVICE_HEART_BEAT_API_URL="/upgrade/api/deviceHeartbeat/push"
DEVICE_UPGRADE_HEART_BEAT_API_URL="/upgrade/api/deviceUpgradeHeartbeat/push"
mac=100000000000
yst_id=800000000000
while [ "$mac" -lt 100000000100 ];do
    #sleep 1;
    ./http_post_singel_device.sh $mac $yst_id &
    mac=`expr $mac + 1`
    yst_id=`expr $yst_id + 1`
done
