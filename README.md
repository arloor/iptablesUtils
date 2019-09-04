# 利用iptables设置端口转发的shell脚本

> 用这几个脚本不收费，所以请大家不要觉得我有义务解答脚本使用的问题。有问题请提issue，请不要通过其他途径联系我，下班时间不想被这些事情烦到。

很多玩VPS的人都会有设置端口转发、进行中转的需求，在这方面也有若干种方案，比如socat、haproxy、brook等等。他们都有一些局限或者问题，比如socat会爆内存，haproxy不支持udp转发。

我比较喜欢iptables。iptables利用linux的一个内核模块进行ip包的转发，工作在linux的内核态，不涉及内核态和用户态的状态转换，因此可以说是所有端口转发方案中性能最好、最稳定的。但他的缺点也显而易见：只支持IP、需要输入一大堆参数。本项目就是为了解决这些缺点，让大家能方便快速地使用最快、最稳定的端口转发方案。

|脚本|功能|优势|限制|
|---   |--|--|---|
|iptables.sh|1. 快速方便地设置本机到目标域名/IP的iptables转发<br><br>2. 仅需输入本地端口号、目标端口号、目标域名/IP即可|1. 原生iptables仅支持ip，该脚本支持域名并<br><br>2. 另外，仅需要用户输入三个参数，避免了复杂地手动调用过程|不能处理ddns(域名解析地ip地址会改变的情况)。<br><br>处理ddns请使用下面两栏介绍的脚本|
|dnat-install.sh|设置到ddns域名的动态转发规则|能正确处理目标域名对应的IP会变的情况(ddns)|尚未发现问题，如有问题请发issue|
|rmPreNatRule.sh|删除本机某端口上的iptables转发规则|仅需要输入端口号即可|无|

> PS: `dnat-install.sh`是全新推出的ddns转发方案，用于代替之前的setCroniptablesDDNS脚本，centos系和debain系都可以使用该脚本。如有bug，请提issue👏

# 用法

# iptables.sh

```shell
wget -O iptables.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables.sh;bash iptables.sh;
```

# dnat-install.sh
```
wget -O dnat-install.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat-install.sh
bash dnat-install.sh
```

按照要求输入三个参数：本地端口号、远程端口号、远程ddns域名即可。该脚本默认开机自启动。

可以使用`journalctl -exu dnat`查看日志，日志形式如下：

```shell
8月 28 20:53:41 cn2 bash[17546]: 转发规则：本地端口[80]=>[github.com:80]
8月 28 20:53:41 cn2 bash[17546]: 正在安装依赖....
8月 28 20:53:42 cn2 bash[17546]: Completed：依赖安装完毕
8月 28 20:53:42 cn2 bash[17546]: 1.端口转发开启  【成功】
8月 28 20:53:42 cn2 bash[17546]: 2.开放iptbales中的FORWARD链  【成功】
8月 28 20:53:42 cn2 bash[17546]: 3.本机网卡IP——172.16.20.24
8月 28 20:53:42 cn2 bash[17546]: 4.开启动态转发！
8月 28 20:53:42 cn2 bash[17546]: 【2019年 08月 28日 星期三 20:53:42 CST】 发现目标域名的IP变为[52.74.223.119]，更新NAT表！
8月 28 20:53:42 cn2 bash[17546]: 当前NAT表如下：(仅供专业人士debug用)
8月 28 20:53:42 cn2 bash[17546]: ###########################################################
8月 28 20:53:42 cn2 bash[17546]: Chain PREROUTING (policy ACCEPT)
8月 28 20:53:42 cn2 bash[17546]: target     prot opt source               destination
8月 28 20:53:42 cn2 bash[17546]: DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:52.74.223.119:80
8月 28 20:53:42 cn2 bash[17546]: DNAT       udp  --  0.0.0.0/0            0.0.0.0/0            udp dpt:80 to:52.74.223.119:80
8月 28 20:53:42 cn2 bash[17546]: Chain POSTROUTING (policy ACCEPT)
8月 28 20:53:42 cn2 bash[17546]: target     prot opt source               destination
8月 28 20:53:42 cn2 bash[17546]: SNAT       tcp  --  0.0.0.0/0            52.74.223.119        tcp dpt:80 to:172.16.20.24
8月 28 20:53:42 cn2 bash[17546]: SNAT       udp  --  0.0.0.0/0            52.74.223.119        udp dpt:80 to:172.16.20.24
8月 28 20:53:42 cn2 bash[17546]: ###########################################################
....
```

# rmPreNatRule.sh

```shell
wget -O rmPreNatRule.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmPreNatRule.sh;bash rmPreNatRule.sh $localport
```
