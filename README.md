# 一些关于iptables转发的工具

socat、haproxy好像是最方便的端口转发工具，但是我喜欢iptables，写了几个脚本，适用于以下需求

- iptables.sh:中转的目标地址可以使用。原来的iptables不支持域名，这个脚本增加域名支持，但不支持ddns域名。适用于所有linux发行版
- setCroniptablesDDNS.sh: 适用于中转目标地址为ddns域名。这个脚本会设置crontab定时任务，每分钟执行一次，检测ddns的ip是否改变，如改变则更新端口映射。适用于centos7
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
若要支持ddns，请使用 https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS.sh;

local port:8388
remote port:1234
target domain/ip:xxx.com
target-ip: xx.xx.xx.xx
local-ip: xx.xx.xx.xx
done!
```

# setCroniptablesDDNS.sh

```shell
rm -f setCroniptablesDDNS.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS.sh;
bash setCroniptablesDDNS.sh


#local port:80
#remote port:58000
#targetDDNS:xxxx.example.com
#done!
#现在每分钟都会检查ddns的ip是否改变，并自动更新
```

# rmPreNatRule.sh

```shell
rm -f rmPreNatRule.sh
wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmPreNatRule.sh;
bash rmPreNatRule.sh $localport
```
