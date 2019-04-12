#! /bin/bash

remotehost=example.com #中转目标host，自行修改
localport=  #中转端口，自行修改
remoteport=  #中转端口，自行修改

red="\033[31m"
black="\033[0m"

if [ $USER != "root" ];then
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi

if [ "$remotehost" = "example.com" ];then
    echo "${red}请修改该脚本，设置remotehost，localport和remoteport${black}"
    echo "${red}注意：remotehost=yourdomain.com 的等号两边不要有空格！${black}"
    echo "${red}本脚本的功能是使用iptables中转ddns机器，所以推荐将该脚本加入crontab定时任务${black}"
    echo "${red}运行该脚本，将检查remotehost指向的ip是否更改，如更改或者为第一次运行，则将设置新的转发${black}"
    exit 1
fi


echo ""
echo 时间：$(date)

# 开启端口转发
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
    echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
fi

if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
    isip=true
    remote=$remotehost

    echo -e "${red}警告：你输入的目标地址是一个ip!${black}"
    echo -e "${red}该脚本的目标是，使用iptables中转到动态ip的vps${black}"
    echo -e "${red}所以remotehost应该填写动态ip的vps的ddns域名${black}"
    exit 1
else
    remote=$(host -t a  $remotehost|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    if [ "$remote" = "" ];then
        echo -e "${red}无法解析remotehost，请填写正确的remotehost！${black}"
        exit 1
    fi
fi

lastremote=$(cat /root/remoteip 2> /dev/null)
if [ "$lastremote" = "$remote" ]; then
    echo 地址解析未变化，退出
    exit 1
fi

echo last-remote-ip: $lastremote
echo new-remote-ip: $remote
echo $remote > /root/remoteip
#if [ "$isip" != "true" ];then
#    echo $remote > /root/remoteip
#fi


## 获取本机地址
local=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "${local}" = "" ]; then
	local=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 )
fi
echo  local-ip: $local
echo  重新设置iptables转发

#删除旧的中转规则
iptables -L PREROUTING -n -t nat --line-number|grep dpt:$localport|awk  '$1!=""{print $1}'|sort -r|xargs -n 1  iptables -t nat  -D PREROUTING
iptables -L POSTROUTING -n -t nat --line-number|grep $remote|grep dpt:$remoteport|awk  '$1!=""{print $1}'|sort -r|xargs -n 1  iptables -t nat  -D POSTROUTING

## 建立新的中转规则
iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A PREROUTING -p udp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A POSTROUTING -p tcp -d $remote --dport $remoteport -j SNAT --to-source $local
iptables -t nat -A POSTROUTING -p udp -d $remote --dport $remoteport -j SNAT --to-source $local
