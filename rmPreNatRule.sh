#! /bin/bash

# 删除本机上指定端口的转发规则，会删除对应的PREROUTING和POSTROUTING规则
# bash rmPreNatRule.sh $localPort

red="\033[31m"
black="\033[0m"

#要删除的转发端口
localport=$1
if [  "$localport"  =  "" ];then
    echo -n "要删除转发的本地端口:" ;read localport
fi

if [ $USER = "root" ];then
	echo "本脚本用途："
    echo "删除本机上指定端口的转发规则，会删除对应的PREROUTING和POSTROUTING规则"
    echo
else
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi



arr1=(`iptables -L PREROUTING -n -t nat --line-number |grep DNAT|grep "dpt:$localport "|sort -r|awk '{print $1,$3,$9}'|tr " " ":"|tr "\n" " "`)
for cell in ${arr1[@]}  # cell= 1:tcp:to:8.8.8.8:543
do
        arr2=(`echo $cell|tr ":" " "`)  #arr2=(1 tcp to 8.8.8.8 543)
        index=${arr2[0]}
        proto=${arr2[1]}
        targetIP=${arr2[3]}
        targetPort=${arr2[4]}
        echo 清除本机$localport端口到$targetIP:$targetPort的${proto}PREROUTING转发规则$index
        iptables -t nat  -D PREROUTING $index
        echo 清除对应的POSTROUTING规则
        toRmIndexs=(`iptables -L POSTROUTING -n -t nat --line-number|grep $targetIP|grep $targetPort|grep $proto|awk  '{print $1}'|sort -r|tr "\n" " "`)
        for cell1 in ${toRmIndexs[@]} 
        do
            iptables -t nat  -D POSTROUTING $cell1
        done
done