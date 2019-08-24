#! /bin/bash

# wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS.sh;bash setCroniptablesDDNS.sh

red="\033[31m"
black="\033[0m"

if [ $USER = "root" ];then
	echo "本脚本用途："
    echo "适用于centos7；设置iptables定时任务，以转发流量到ddns的vps上"
    echo
else
    echo   -e "${red}请使用root用户执行本脚本!! ${black}"
    exit 1
fi

cd

echo "正在安装依赖...."
yum install -y wget bind-utils &> /dev/null
cd /usr/local
rm -f /usr/local/iptables4ddns.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh  &> /dev/null
chmod +x /usr/local/iptables4ddns.sh
echo "Done!"
echo ""


echo -n "本地端口号:" ;read localport
echo -n "远程端口号:" ;read remoteport
echo -n "目标DDNS:" ;read targetDDNS

# 判断端口是否为数字
echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]&& valid=true

if [ "$valid" = "" ];then
   echo  -e "${red}本地端口和目标端口请输入数字！！${black}"
   exit 1;
fi

IPrecordfile=${localport}[${targetDDNS}:${remoteport}]
# 开机强制刷新一次
chmod +x /etc/rc.d/rc.local
echo "rm -f /root/$IPrecordfile" >> /etc/rc.d/rc.local
# 替换下面的localport remoteport targetDDNS
echo "/bin/bash /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS $IPrecordfile &>> /root/iptables${localport}.log" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
# 定时任务，每分钟检查一下
echo "* * * * * root /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS $IPrecordfile &>> /root/iptables${localport}.log" >> /etc/crontab
cd
rm -f /root/$IPrecordfile
bash /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS $IPrecordfile &>> /root/iptables${localport}.log
echo "done!"
echo "现在每分钟都会检查ddns的ip是否改变，并自动更新"
