#! /bin/bash

# 删除本机上指定端口的转发规则，会删除对应的PREROUTING和POSTROUTING规则
# bash rmPreNatRule.sh $localPort

if [ "$1" == "" ];then
    echo 'Usage: bash rmPreNatRule.sh $localport'
    exit 1
fi

if [ "$3" = "" ];then
    iptables -L PREROUTING -n -t nat |grep DNAT|grep dpt:$1|awk '{print $8}'|tail -1|tr "\n" " "|xargs -d :  ./deletePre.sh
    iptables -L PREROUTING -n -t nat --line-number|grep dpt:$1|awk  '$1!=""{print $1}'|sort -r|xargs -n 1  iptables -t nat  -D PREROUTING
else
    iptables -L POSTROUTING -n -t nat --line-number|grep $2|grep $3|awk  '{print $1}'|sort -r|xargs -n 1 iptables -t nat  -D POSTROUTING
fi
