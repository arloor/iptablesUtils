#! /bin/bash

base=/etc/dnat
service dnat stop
systemctl disable dnat
rm -rf $base
