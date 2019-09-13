if [ $USER != "root" ];then
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi

#要删除的转发端口
localport=$1
if [  "$localport"  =  "" ];then
    echo -n "要删除的ddns转发的本地端口:" ;read localport
fi

# 判断端口是否为数字
echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && valid=true
if [ "$valid" = "" ];then
   echo  -e "本地端口请输入数字！！"
   exit 1;
fi

service dnat$localport stop
systemctl disable  dnat$localport
rm -f /lib/systemd/system/dnat$localport.service
rm -f /etc/dnat/$localport.conf 

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