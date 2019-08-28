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

mkdir /etc/dnat
cat > /etc/dnat/dnat.conf <<EOF
#本地端口号
localport=$localport
#远程端口号
remoteport=$remoteport
#远程域名
remotehost=$remotehost
USER=root
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/sbin:/bin
EOF

cat > /usr/local/bin/dnat.sh <<\EOF
#! /bin/bash
localport=$1  
remoteport=$2  
remotehost=$3 
red="\033[31m"
black="\033[0m"

echo  "转发规则：本地端口[$localport]=>[$remotehost:$remoteport]"
remoteIP=unknown

if [ "$USER" != "root" ];then
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi

# 检查参数个数
if [ "$remotehost" = "" ];then
    echo -e "${red}Usage: bash iptables4ddns.sh localport remoteport remotehost ${black}"
    exit 1
fi

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

# 开启端口转发
echo "1.端口转发开启  【成功】"
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
    echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
fi

#开放FORWARD链
echo "2.开放iptbales中的FORWARD链  【成功】"
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
if [ "${local}" = "" ]; then
        local=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 )
fi
echo  "3.本机网卡IP——$local"
echo "4.开启动态转发！"
echo ""


while true ;
do
    remote=$(host -t a  $remotehost|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    if [ "$remote" = "" ];then
        echo -e "${red}无法解析remotehost，请填写正确的remotehost！${black}"
        exit 1
    fi
    if [ "$remote" != "$remoteIP" ];then
        echo  -e "【${red}$(date)${black}】 发现目标域名的IP变为[${red}$remote${black}]，更新NAT表！"
        echo  -e "当前NAT表如下：(仅供专业人士debug用)"
        #删除旧的中转规则
        arr1=(`iptables -L PREROUTING -n -t nat --line-number |grep DNAT|grep "dpt:$localport "|sort -r|awk '{print $1,$3,$9}'|tr " " ":"|tr "\n" " "`)
        for cell in ${arr1[@]}  # cell= 1:tcp:to:8.8.8.8:543
        do
            arr2=(`echo $cell|tr ":" " "`)  #arr2=(1 tcp to 8.8.8.8 543)
            index=${arr2[0]}
            proto=${arr2[1]}
            targetIP=${arr2[3]}
            targetPort=${arr2[4]}
            # echo 清除本机$localport端口到$targetIP:$targetPort的${proto}的PREROUTING转发规则[$index]
            iptables -t nat  -D PREROUTING $index
            # echo ==清除对应的POSTROUTING规则
            toRmIndexs=(`iptables -L POSTROUTING -n -t nat --line-number|grep $targetIP|grep $targetPort|grep $proto|awk  '{print $1}'|sort -r|tr "\n" " "`)
            for cell1 in ${toRmIndexs[@]}
            do
                iptables -t nat  -D POSTROUTING $cell1
            done
        done

        ## 建立新的中转规则
        iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $remote:$remoteport
        iptables -t nat -A PREROUTING -p udp --dport $localport -j DNAT --to-destination $remote:$remoteport
        iptables -t nat -A POSTROUTING -p tcp -d $remote --dport $remoteport -j SNAT --to-source $local
        iptables -t nat -A POSTROUTING -p udp -d $remote --dport $remoteport -j SNAT --to-source $local
        echo "###########################################################"
        iptables -L PREROUTING -n -t nat
        iptables -L POSTROUTING -n -t nat
        echo "###########################################################"
        echo ""
        echo ""

        remoteIP=$remote
    fi
    sleep 120
done;
EOF

cat > /lib/systemd/system/dnat.service <<\EOF
[Unit]
Description=动态设置iptables转发规则
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root/
EnvironmentFile=/etc/dnat/dnat.conf
ExecStart=/bin/bash /usr/local/bin/dnat.sh $localport $remoteport $remotehost
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnat
service dnat stop
service dnat start

echo  "已设置转发规则：本地端口[$localport]=>[$remotehost:$remoteport]"
echo  "输入 journalctl -exu dnat 查看日志"