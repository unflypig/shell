#!/bin/sh
DOMAIN_PATH="$1"
OUT_PATH="$2"
rm $OUT_PATH
domain_list="`cat $DOMAIN_PATH`"
for domain in $domain_list;do
    echo "server=/$domain/127.0.0.1#5300"  >> $OUT_PATH
    echo "ipset=/$domain/gfwipset"  >> $OUT_PATH
done
