#! /bin/bash

base=/etc/dnat
systemctl disable --now dnat
rm -rf $base
iptables -t nat -F PREROUTING
iptables -t nat -F POSTROUTING
