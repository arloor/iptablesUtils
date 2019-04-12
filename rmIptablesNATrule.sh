#! /bin/bash

# wget  https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmIptablesNATrule.sh;bash rmIptablesNATrule.sh;rm -f rmIptablesNATrule.sh;

echo "本脚本将会删除本地端口中转到远程ip的远程端口的iptables规则"

echo -n "远程ip地址:" ;read remote
echo -n "远程端口:" ;read remoteport
echo -n "本地端口:" ;read localport

#删除旧的中转规则
iptables -L PREROUTING -n -t nat --line-number|grep dpt:$localport|awk  '$1!=""{print $1}'|sort -r|xargs -n 1  iptables -t nat  -D PREROUTING 2> /dev/null
iptables -L POSTROUTING -n -t nat --line-number|grep $remote|grep dpt:$remoteport|awk  '$1!=""{print $1}'|sort -r|xargs -n 1  iptables -t nat  -D POSTROUTING 2> /dev/null

echo "done!"