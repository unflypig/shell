pre_rx_tr="`ifconfig eth0.2|grep "RX bytes"|grep -oE "RX bytes:[0-9]+"|grep -oE "[0-9]+"`"
sleep 5
cur_rx_tr="`ifconfig eth0.2|grep "RX bytes"|grep -oE "RX bytes:[0-9]+"|grep -oE "[0-9]+"`"
speed="`expr $cur_rx_tr - $pre_rx_tr`"
speed="`expr $speed / 5`"
speed="`expr $speed / 1024`"
echo "${speed}KB/s"
