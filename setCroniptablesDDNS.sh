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
yum install -y wget bind-utils
cd /usr/local
rm -f /usr/local/iptables4ddns.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh;
chmod +x /usr/local/iptables4ddns.sh

echo -n "local port:" ;read localport
echo -n "remote port:" ;read remoteport
echo -n "targetDDNS:" ;read targetDDNS
# 开机强制刷新一次
chmod +x /etc/rc.d/rc.local
echo "rm -f /root/remoteip" >> /etc/rc.d/rc.local
# 替换下面的localport remoteport targetDDNS
echo "/bin/bash /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS &>> /root/iptables.log" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
# 定时任务，每分钟检查一下
echo "* * * * * root /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS &>> /root/iptables.log" >> /etc/crontab
cd
bash /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS &>> /root/iptables.log
echo "done!"
echo "现在每分钟都会检查ddns的ip是否改变，并自动更新"