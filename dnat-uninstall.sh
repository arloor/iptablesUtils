#! /bin/bash

base=/etc/dnat
systemctl disable --now dnat
rm -rf $base
