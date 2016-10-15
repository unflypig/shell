#!/bin/bash
#set -x
#Mac="FC:FF:FF:FF:FF:FF"
Mac=$1
cmd=$2
num=$3
#num=2
if [ $1 = "-h" ];then
    echo "./kf_mac_self_add.sh [MAC] [CMD] [NUM]"
    echo "CMD=0/1 add/sub"
    exit 
fi
mac6=$(echo $Mac| awk -F':' '{print $6}')
((mac6=16#$mac6))
mac6=$mac6
mac5=$(echo $Mac| awk -F':' '{print $5}')
((mac5=16#$mac5))
mac5=$mac5
mac4=$(echo $Mac| awk -F':' '{print $4}')
((mac4=16#$mac4))
mac4=$mac4
mac3=$(echo $Mac| awk -F':' '{print $3}')
((mac3=16#$mac3))
mac3=$mac3
mac2=$(echo $Mac| awk -F':' '{print $2}')
((mac2=16#$mac2))
mac2=$mac2
mac1=$(echo $Mac| awk -F':' '{print $1}')
((mac1=16#$mac1))
mac1=$mac1

#num=$((num - 1))
function mac_add_num(){
    local num=$1
    for i in $(seq $num); do
        mac6=$((mac6+1))
        if (( $mac6 > 255 )) ; then
            mac5=$((mac5+1))
            mac6=$((mac6-256))
            if (( $mac5 > 255 )) ; then
                mac4=$((mac4+1))
                mac5=$((mac5-256))
                if (( $mac4 > 255 )) ; then
                    mac3=$((mac3+1))
                    mac4=$((mac4-256))
                    if (( $mac3 > 255 )) ; then
                        mac2=$((mac2+1))
                        mac3=$((mac3-256))
                        if (( $mac2 > 255 )) ; then
                            mac1=$((mac1+1))
                            mac2=$((mac2-256))
                            if (( $mac1 > 255 ));then
                                echo "ERROR:MAC can not more than FFFFFFFFFFFF!"
                                exit 1
                            fi
                        fi
                    fi
                fi
            fi
        fi
        mac6tmp=$(printf %02x $mac6)
        mac5tmp=$(printf %02x $mac5)
        mac4tmp=$(printf %02x $mac4)
        mac3tmp=$(printf %02x $mac3)
        mac2tmp=$(printf %02x $mac2)
        mac1tmp=$(printf %02x $mac1)
        macTmp=$mac1tmp:$mac2tmp:$mac3tmp:$mac4tmp:$mac5tmp:$mac6tmp
    done
}
function mac_sub_num(){
    local num=$1
    for i in $(seq $num); do
        mac6=$((mac6-1))
        if (( $mac6 < 0 )) ; then
            mac5=$((mac5-1))
            mac6=$((256-mac6))
            if (( $mac5 < 0 )) ; then
                mac4=$((mac4-1))
                mac5=$((256-mac5))
                if (( $mac4 < 0 )) ; then
                    mac3=$((mac3-1))
                    mac4=$((256-mac4))
                    if (( $mac3 < 0 )) ; then
                        mac2=$((mac2-1))
                        mac3=$((256-mac3))
                        if (( $mac2 < 0 )) ; then
                            mac1=$((mac1-1))
                            mac2=$((256-mac2))
                            if (( $mac1 < 0 ));then
                                echo "ERROR:MAC can not less than 000000000000!"
                                exit 1
                            fi
                        fi
                    fi
                fi
            fi
        fi
        mac6tmp=$(printf %02x $mac6)
        mac5tmp=$(printf %02x $mac5)
        mac4tmp=$(printf %02x $mac4)
        mac3tmp=$(printf %02x $mac3)
        mac2tmp=$(printf %02x $mac2)
        mac1tmp=$(printf %02x $mac1)
        macTmp=$mac1tmp:$mac2tmp:$mac3tmp:$mac4tmp:$mac5tmp:$mac6tmp
    done
}
#0/1 add/sub
case $cmd in
    0)
        mac_add_num $num
        ;;
    1)
        mac_sub_num $num
        ;;
    *)
        echo "ERROR:Bad command,use -h to see how to use!"
        exit 2
    ;;
esac
echo $macTmp
