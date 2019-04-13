# 一些关于iptables转发的工具

socat、haproxy好像是最方便的端口转发工具，但是我喜欢iptables，写了几个脚本，适用于以下需求

- iptables.sh:中转的目标地址可以使用。原来的iptables不支持域名，这个脚本增加域名支持，但不支持ddns域名
- iptables4ddns.sh: 适用于中转目标地址为ddns域名。这个脚本推荐加入crontab定时任务，每分钟执行一次，检测ddns的ip是否改变，如改变则更新端口映射
- rmPreNatRule.sh: 删除本机上对应端口的中转规则，会同时删除PREROUTING和POSTROUTING链的相关规则。

# 用法

# iptables.sh

```shell
wget  https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables.sh;
bash iptables.sh;
rm -f iptables.sh;
```

输出如下：
```shell
本脚本用途：
设置本机tcp和udp端口转发
原始iptables仅支持ip地址，该脚本增加域名支持（要求域名指向的主机ip不变）
若要支持ddns，请使用 https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh;

local port:8388
remote port:1234
target domain/ip:xxx.com
target-ip: xx.xx.xx.xx
local-ip: xx.xx.xx.xx
```

# iptables4ddns.sh

```shell
sudo su
yum install -y wget
cd /usr/local
rm -f /usr/local/iptables4ddns.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables4ddns.sh;
chmod +x /usr/local/iptables4ddns.sh
# 开机强制刷新一次
echo "rm -f /root/remoteip" >> /etc/rc.d/rc.local
# 替换下面的localport remoteport targetDDNS
echo "/bin/bash /usr/local/iptables4ddns.sh $localport $remoteport $targetDDNS &>> /root/iptables.log" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
# 定时任务，每分钟检查一下
echo "* * * * * root /usr/local/iptables4ddns.sh localport remoteport remoteDDNS &>> /root/iptables.log" >> /etc/crontab
cd 
```

# rmPreNatRule.sh

```shell
rm -f rmPreNatRule.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmPreNatRule.sh;
bash rmPreNatRule.sh $localport
```