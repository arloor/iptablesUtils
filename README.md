# 利用iptables设置端口转发的shell脚本

电报讨论组 https://t.me/popstary

**本项目支持转发到ddns域名、支持udp转发，但不支持端口段转发**

很多玩VPS的人都会有设置端口转发、进行中转的需求，在这方面也有若干种方案，比如socat、haproxy、brook等等。他们都有一些局限或者问题，比如socat会爆内存，haproxy不支持udp转发。

我比较喜欢iptables。iptables利用linux的一个内核模块进行ip包的转发，工作在linux的内核态，不涉及内核态和用户态的状态转换，因此可以说是所有端口转发方案中最稳定的。但他的缺点也显而易见：只支持IP、需要输入一大堆参数。本项目就是为了解决这些缺点，让大家能方便快速地使用最快、最稳定的端口转发方案。


## 用法


```shell
# 如果vps不能访问 raw.githubusercontent.com 推荐使用这个
wget --no-check-certificate -qO natcfg.sh http://www.arloor.com/sh/iptablesUtils/natcfg.sh && bash natcfg.sh
```
或

```
wget --no-check-certificate -qO natcfg.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/natcfg.sh && bash natcfg.sh
```

输出如下：

```
#############################################################
# Usage: setup iptables nat rules for domian/ip             #
# Website:  http://www.arloor.com/                          #
# Author: ARLOOR <admin@arloor.com>                         #
# Github: https://github.com/arloor/iptablesUtils           #
#############################################################

你要做什么呢（请输入数字）？Ctrl+C 退出本脚本
1) 增加转发规则          3) 列出所有转发规则
2) 删除转发规则          4) 查看当前iptables配置
#?
```

此时按照需要，输入1-4中的任意数字，然后按照提示即可

## 卸载

```shell
wget --no-check-certificate -qO uninstall.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat-uninstall.sh && bash uninstall.sh
```

## trojan转发

总是有人说，不能转发trojan，这么说的人大部分是证书配置不对。最简单的解决方案是：客户端选择不验证证书。复杂一点是自己把证书和中转机的域名搭配好。

小白记住一句话就好：客户端不验证证书。

-----------------------------------------------------------------------------

## 推荐新项目——使用nftables实现nat转发

iptables的后继者nftables已经在debain和centos最新的操作系统中作为生产工具提供，nftables提供了很多新的特性，解决了iptables很多痛点。

因此创建了一个新的项目[/arloor/nftables-nat-rust](https://github.com/arloor/nftables-nat-rust)。该项目使用nftables作为nat转发实现，相比本项目具有如下优点：

1. 支持端口段转发
2. 转发规则使用配置文件，可以进行备份以及导入
3. 更加现代

所以**强烈推荐**使用[/arloor/nftables-nat-rust](https://github.com/arloor/nftables-nat-rust)。不用担心，本项目依然可以正常稳定使用。

PS: 新旧两个项目并不兼容，切换到新项目时，请先卸载此项目

## 赏个鸡腿吧

<img src="http://cdn.arloor.com/wechat_shoukuan.jpg" alt="" width="400px" style="max-width: 100%;">

