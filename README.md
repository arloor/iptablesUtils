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

```shell

```