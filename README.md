# 利用iptables设置端口转发的shell脚本

> 各位大佬fork之余请给个star吧

很多玩VPS的人都会有设置端口转发、进行中转的需求，在这方面也有若干种方案，比如socat、haproxy、brook等等。他们都有一些局限或者问题，比如socat会爆内存，haproxy不支持udp转发。

我比较喜欢iptables。iptables利用linux的一个内核模块进行ip包的转发，工作在linux的内核态，不涉及内核态和用户态的状态转换，因此可以说是所有端口转发方案中性能最好、最稳定的。但他的缺点也显而易见：只支持IP、需要输入一大堆参数。本项目就是为了解决这些缺点，让大家能方便快速地使用最快、最稳定的端口转发方案。

|脚本|功能|优势|限制|
|---   |--|--|---|
|iptables.sh|1. 快速方便地设置本机到目标域名/IP的iptables转发<br><br>2. 仅需输入本地端口号、目标端口号、目标域名/IP即可|1. 原生iptables仅支持ip，该脚本支持域名并<br><br>2. 另外，仅需要用户输入三个参数，避免了复杂地手动调用过程|不能处理ddns(域名解析地ip地址会改变的情况)。<br><br>处理ddns请使用下面两栏介绍的脚本|
|setCroniptablesDDNS.sh|设置到ddns域名的动态转发规则|能正确处理目标域名对应的IP会变的情况(ddns)|只适用于centos系统|
|setCroniptablesDDNS-debian.sh|同上|同上|只适用于debain系统<br><br>已知bug，开机不能自启动|
|rmPreNatRule.sh|删除本机某端口上的iptables转发规则|仅需要输入端口号即可|无|


# 用法

# iptables.sh

```shell
wget -O iptables.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables.sh;bash iptables.sh;
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

适用于centos系

```shell
wget -O setCroniptablesDDNS.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS.sh;bash setCroniptablesDDNS.sh
```

```
输出如下：
#local port:80
#remote port:58000
#targetDDNS:xxxx.example.com
#done!
#现在每分钟都会检查ddns的ip是否改变，并自动更新
```

# setCroniptablesDDNS-debian.sh

适用于debain系

```
wget -O setCroniptablesDDNS-debian.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/setCroniptablesDDNS-debian.sh;bash setCroniptablesDDNS-debian.sh
```

# rmPreNatRule.sh

```shell
wget -O rmPreNatRule.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmPreNatRule.sh;bash rmPreNatRule.sh $localport
```

# 正在进行的一项实验：

这个最方便

```
wget -O dnat.sh wget https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat.sh
bash dnat.sh 80 80 arloor.com &
# 本地80 转发到arloor.com:80
```
