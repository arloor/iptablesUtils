#! /bin/bash
echo -n "本地端口号:" ;read localport
echo -n "远程端口号:" ;read remoteport
echo -n "目标DDNS:" ;read remotehost

red="\033[31m"
black="\033[0m"

# 判断端口是否为数字
echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]&& valid=true
if [ "$valid" = "" ];then
   echo  -e "${red}本地端口和目标端口请输入数字！！${black}"
   exit 1;
fi


# 检查输入的不是IP
if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
    isip=true
    remote=$remotehost

    echo -e "${red}警告：你输入的目标地址是一个ip!${black}"
    echo -e "${red}该脚本的目标是，使用iptables中转到动态ip的vps${black}"
    echo -e "${red}所以remotehost参数应该是动态ip的vps的ddns域名${black}"
    exit 1
fi

echo "正在安装依赖...."
yum install -y bind-utils &> /dev/null
apt install -y dnsutils &> /dev/null
echo "Completed：依赖安装完毕"
echo ""

mkdir /etc/dnat 2>/dev/null

touch /etc/dnat/conf
sed -i "s/$localport>.*/$localport>$remotehost:$remoteport/g" /etc/dnat/conf

sed -i '1i\$localport>$remotehost:$remoteport' /etc/dnat/conf
cat /etc/dnat/conf




cat > /lib/systemd/system/dnat.service <<\EOF
[Unit]
Description=动态设置iptables转发规则
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root/
EnvironmentFile=
ExecStart=/bin/bash /usr/local/bin/dnat.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnat
service dnat stop
service dnat start
