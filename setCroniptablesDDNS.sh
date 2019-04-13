#! /bin/bash

# wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS.sh;bash setCroniptablesDDNS.sh

sudo su
yum install -y wget
cd /usr/local
rm -f /usr/local/iptables4ddns.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh;
chmod +x /usr/local/iptables4ddns.sh

echo -n "local port:" ;read localport
echo -n "local port:" ;read remoteport
echo -n "targetDDNS:" ;read targetDDNS
# 开机强制刷新一次
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