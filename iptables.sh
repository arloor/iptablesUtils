#! /bin/bash

# wget  https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables.sh;bash iptables.sh;rm -f iptables.sh;

red="\033[31m"
black="\033[0m"

if [ $USER = "root" ];then
	echo "本脚本用途："
    echo "设置本机tcp和udp端口转发"
    echo  "原始iptables仅支持ip地址，该脚本增加域名支持（要求域名指向的主机ip不变），如果是centos系统请先执行：yum install bind-utils"
    echo "若要支持ddns，请使用 https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh;"
    echo
else
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi

 #中转目标host，自行修改
remotehost=
#中转端口，自行修改
remoteport=
localport=
if [  "$localport"  =  "" ];then
    echo -n "local port:" ;read localport
fi

if [  "$remoteport"  =  "" ];then
    echo -n "remote port:" ;read remoteport
fi
if [  "$remotehost"  =  "" ];then
    echo -n "target domain/ip:" ;read remotehost
fi

if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
    isip=true
    remote=$remotehost
else
    echo "正在安装host命令....."
    yum install -y wget bind-utils &> /dev/null  #为centos系列安装依赖
    apt install -y wget dnsutils  &> /dev/null   #为debain系列安装依赖
    echo "Done"
    remote=$(host -t a  $remotehost|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
fi
if [ "$remote" = "" ];then
    echo -e "${red}无法解析remotehost，请填写正确的remotehost！${black}"
    exit 1
fi




# 开启端口转发
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
    echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
fi

#开放FORWARD链
arr1=(`iptables -L FORWARD -n  --line-number |grep "REJECT"|grep "0.0.0.0/0"|sort -r|awk '{print $1,$2,$5}'|tr " " ":"|tr "\n" " "`)  #16:REJECT:0.0.0.0/0 15:REJECT:0.0.0.0/0
for cell in ${arr1[@]}
do
    arr2=(`echo $cell|tr ":" " "`)  #arr2=16 REJECT 0.0.0.0/0
    index=${arr2[0]}
    echo 删除禁止FOWARD的规则——$index
    iptables -D FORWARD $index
done
iptables --policy FORWARD ACCEPT

## 获取本机地址
local=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "x${local}" = "x" ]; then
	local=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 )
fi
echo target-ip: $remote
echo  local-ip: $local

##如果有旧的，冲突的规则则删除
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
#设置新的中转规则
iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A PREROUTING -p udp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A POSTROUTING -p tcp -d $remote --dport $remoteport -j SNAT --to-source $local
iptables -t nat -A POSTROUTING -p udp -d $remote --dport $remoteport -j SNAT --to-source $local
echo 端口转发成功
