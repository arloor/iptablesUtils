# 利用iptables设置端口转发的shell脚本

> 用这几个脚本不收费，所以请大家不要觉得我有义务解答脚本使用的问题。有问题请提issue，请不要通过其他途径联系我，下班时间不想被这些事情烦到。

> **PS: 本项目支持udp转发，但不支持端口段转发**

> 老板们，本项目还是在不断开发的，推荐有兴趣的人点star而不是fork，因为fork出的项目是收不到更新的——一个建议而已

很多玩VPS的人都会有设置端口转发、进行中转的需求，在这方面也有若干种方案，比如socat、haproxy、brook等等。他们都有一些局限或者问题，比如socat会爆内存，haproxy不支持udp转发。

我比较喜欢iptables。iptables利用linux的一个内核模块进行ip包的转发，工作在linux的内核态，不涉及内核态和用户态的状态转换，因此可以说是所有端口转发方案中性能最好、最稳定的。但他的缺点也显而易见：只支持IP、需要输入一大堆参数。本项目就是为了解决这些缺点，让大家能方便快速地使用最快、最稳定的端口转发方案。

下面分转发静态解析域名和动态解析域名(ddns)两种场景介绍如何使用本项目的脚本。


## 转发静态解析域名

静态解析域名就是在较长的时间域名对应的ip不会变化的情况，例如阿里云、搬瓦工这些非nat的vps就是这种场景。转发到静态域名解析的目标场景下使用`iptables.sh`和`rmPreNatRule.sh`分别增加和删除转发规则。

使用方式如下：

**转发本地8388端口流量到google.com域名的8388端口**

输入以下命令：

```shell
 wget -O iptables.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/iptables.sh;
 bash iptables.sh;
 ```
 
 按照提示依次输入本地端口号、目标端口号、目标域名即可，脚本执行过程的输出如下：
 
 ```shell
本脚本用途：
设置本机tcp和udp端口转发
原始iptables仅支持ip地址，该脚本增加域名支持（要求域名指向的主机ip不变）
若要支持ddns，请使用 dnat-install.sh

local port:8388
remote port:8388
target domain/ip:google.com
正在安装host命令.....
Done
....
target-ip: 74.125.24.102
local-ip: 172.21.xx.xx
端口转发成功
###########################################################
当前NAT表如下：(仅供专业人士debug用)
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8388 to:74.125.24.102:8388
DNAT       udp  --  0.0.0.0/0            0.0.0.0/0            udp dpt:8388 to:74.125.24.102:8388
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
SNAT       tcp  --  0.0.0.0/0            74.125.24.102        tcp dpt:8388 to:172.xx.xx.130
SNAT       udp  --  0.0.0.0/0            74.125.24.102        udp dpt:8388 to:172.xx.xx.130
###########################################################
```

**删除刚刚设置的本地8388端口上的转发规则**

输入以下命令：

```
wget -O rmPreNatRule.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/rmPreNatRule.sh;
bash rmPreNatRule.sh $localport
```

按照提示输入本地端口号8388，即可删除刚刚设置的本地8388转发到google.com:8388的转发规则，输出如下：

```
要删除转发的本地端口:8388
本脚本用途：
删除本机上指定端口的转发规则，会删除对应的PREROUTING和POSTROUTING规则

清除本机8388端口到74.125.24.102:8388的udpPREROUTING转发规则2
清除对应的POSTROUTING规则
清除本机8388端口到74.125.24.102:8388的tcpPREROUTING转发规则1
清除对应的POSTROUTING规则
```

**一些需要额外说明的东西**

1. 增加转发规则是一次性的
    1. iptables.sh在添加了几条iptables规则立即结束，不会有后台进程长时间运行消耗内存和CPU；
    2. “一次性”的另一个意思是所设定的转发规则在重启机器后就会被删除——这是iptables的特性，使用iptables-service可以保存这些规则使其重启时不被删除，但这里不介绍。
2.  重复对同一本地端口执行iptables.sh，会自动地覆盖（删除）之前设定的转发规则，不需要手动调用`rmPreNatRule.sh`


## 转发流量到动态域名解析（ddns）的服务器

这种场景适用于动态IP的vps，例如香港、台湾的家宽nat机器。这种场景使用`dnat-install.sh`和`dnat-uninstall.sh`来增加和删除ddns流量转发规则。

我们假设github.com这个域名就是一个ddns域名，其对应的IP会不定时地发生变化，下面以它为例进行ddns流量转发规则的增加和删除。

**设置本地8080到github.com的8080端口的流量转发规则**

执行以下命令：

```
wget -O dnat-install.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat-install.sh
bash dnat-install.sh
```

按照提示依次输入本地端口号、目标端口号、目标域名即可，脚本执行过程的输出如下：

```
本地端口号:8080 
远程端口号:8080
目标DDNS:github.com
正在安装依赖....
Completed：依赖安装完毕

Created symlink from /etc/systemd/system/multi-user.target.wants/dnat8080.service to /usr/lib/systemd/system/dnat8080.service.
Redirecting to /bin/systemctl stop dnat8080.service
Redirecting to /bin/systemctl start dnat8080.service
已设置转发规则：本地端口[8080]=>[github.com:8080]
输入 journalctl -exu dnat8080 查看日志
```

**删除刚刚设置的转发规则**

执行以下命令：

```
wget -O dnat-uninstall.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat-uninstall.sh
bash dnat-uninstall.sh
```

输入本地端口号8080即可，输出如下：

```
要删除的ddns转发的本地端口:8080
Redirecting to /bin/systemctl stop dnat8080.service
Removed symlink /etc/systemd/system/multi-user.target.wants/dnat8080.service.
清除本机8080端口到52.74.223.119:8080的udpPREROUTING转发规则2
清除对应的POSTROUTING规则
清除本机8080端口到52.74.223.119:8080的tcpPREROUTING转发规则1
清除对应的POSTROUTING规则
```

这样就删除了刚刚设置的针对ddns的流量转发规则。



**一些需要额外说明的东西**

1. `dnat-install.sh`执行完毕后会产生一个linux的service，它周期性地查询ddns指向的IP是否变化，如果变化，则会更新转发规则
2. dnat-install设置的ddns流量转发在重启后不会失效。
3. 对本地同一端口多次执行dnat-install会自动覆盖老的规则，无需手动删除。
4. 如果不清楚自己在本地哪些端口上设置了ddns流量转发，可以执行以下命令查看：

```
ls /lib/systemd/system/dnat*.service
```

会有如下输出：

```
/lib/systemd/system/dnat8080.service
```

这表明8080端口上有ddns流量转发。此时可以对8080端口执行`dnat-uninstall.sh`脚本删除该端口上的转发。
