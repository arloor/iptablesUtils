red="\033[31m"
black="\033[0m"

base=/etc/dnat
mkdir $base 2>/dev/null
conf=$base/conf
touch $conf

# wget -qO natcfg.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/natcfg.sh && bash natcfg.sh
echo -e "${red}用途${black}: 便捷的设置iptables端口转发"
echo -e "${red}注意1${black}: 到域名的转发规则在添加后需要等待2分钟才会生效，且在机器重启后仍然有效"
echo -e "${red}注意2${black}: 到IP的转发规则在重启后会失效，这是iptables的特性"
echo
setupService(){
    wget -qO /usr/local/bin/dnat.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat.sh||{
        echo "脚本不存在，请通过github提交issue通知作者"
        exit 1
    }
    echo 


cat > /lib/systemd/system/dnat.service <<\EOF
[Unit]
Description=动态设置iptables转发规则
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root/
EnvironmentFile=
ExecStart=/bin/bash /usr/local/bin/dnat.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnat > /dev/null 2>&1
service dnat stop > /dev/null 2>&1
service dnat start > /dev/null 2>&1
}


## 获取本机地址
localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "${localIP}" = "" ]; then
        localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1|head -n 1 )
fi

rmIptablesNat(){
    #删除旧的中转规则
        local arr1=(`iptables -L PREROUTING -n -t nat --line-number |grep DNAT|grep "dpt:$1 "|sort -r|awk '{print $1,$3,$9}'|tr " " ":"|tr "\n" " "`)
        for cell in ${arr1[@]}  # cell= 1:tcp:to:8.8.8.8:543
        do
            local arr2=(`echo $cell|tr ":" " "`)  #arr2=(1 tcp to 8.8.8.8 543)
            local index=${arr2[0]}
            local proto=${arr2[1]}
            local targetIP=${arr2[3]}
            local targetPort=${arr2[4]}
            # echo 清除本机$localport端口到$targetIP:$targetPort的${proto}的PREROUTING转发规则[$index]
            iptables -t nat  -D PREROUTING $index
            # echo ==清除对应的POSTROUTING规则
            local toRmIndexs=(`iptables -L POSTROUTING -n -t nat --line-number|grep SNAT|grep $targetIP|grep dpt:$targetPort|grep $proto|awk  '{print $1}'|sort -r|tr "\n" " "`)
            for cell1 in ${toRmIndexs[@]}
            do
                iptables -t nat  -D POSTROUTING $cell1
            done
        done
}

addDnat(){
    local localport=
    local remoteport=
    local remotehost=
    local valid=
    echo -n "本地端口号:" ;read localport
    echo -n "远程端口号:" ;read remoteport
    # echo $localport $remoteport
    # 判断端口是否为数字
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
        echo  -e "${red}本地端口和目标端口请输入数字！！${black}"
        return 1;
    }

    echo -n "目标域名:" ;read remotehost
    # 检查输入的不是IP
    if [ "$remotehost" = "" -o "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
        isip=true
        remote=$remotehost
        echo -e "${red}请输入一个ddns域名${black}"
        return 1
    fi

    setupService
    echo "成功添加转发规则 $localport>$remotehost:$remoteport 大约两分钟后规则会生效"

    sed -i "s/^$localport.*/$localport>$remotehost:$remoteport/g" $conf
    [ "$(cat $conf|grep "$localport>$remotehost:$remoteport")" = "" ]&&{
            cat >> $conf <<LINE
$localport>$remotehost:$remoteport
LINE
    }
}

rmDnat(){
    local localport=
    echo -n "本地端口号:" ;read localport
    sed -i "/^$localport>.*/d" $conf

    rmIptablesNat $localport
    #删除临时文件  
    rm -f $base/${1}IP  
}

testVars(){
    local localport=$1
    local remotehost=$2
    local remoteport=$3
    # 判断端口是否为数字
    local valid=
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
       # echo  -e "${red}本地端口和目标端口请输入数字！！${black}";
       return 1;
    }

    # 检查输入的不是IP
    if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
        local isip=true
        local remote=$remotehost

        # echo -e "${red}警告：你输入的目标地址是一个ip!${black}"
        return 2;
    fi
}

lsDnat(){
    arr1=(`cat $conf`)
for cell in ${arr1[@]}  
do
    arr2=(`echo $cell|tr ":" " "|tr ">" " "`)  #arr2=16 REJECT 0.0.0.0/0
    # 过滤非法的行
    [ "${arr2[2]}" != "" -a "${arr2[3]}" = "" ]&& testVars ${arr2[0]}  ${arr2[1]} ${arr2[2]}&&{
        echo "转发规则： ${arr2[0]}>${arr2[1]}:${arr2[2]}"
    }
done
}

addSnat(){
    local localport=
    local remoteport=
    local remotehost=
    echo -n "本地端口号:" ;read localport
    echo -n "远程端口号:" ;read remoteport
    # echo $localport $remoteport
    # 判断端口是否为数字
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
        echo  -e "${red}本地端口和目标端口请输入数字！！${black}"
        return 1;
    }

    echo -n "目标IP:" ;read remotehost
    # 检查输入的不是IP
    if [ "$remotehost" = "" -o "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
        rmIptablesNat $localport

        ## 建立新的中转规则
        iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $remotehost:$remoteport
        iptables -t nat -A PREROUTING -p udp --dport $localport -j DNAT --to-destination $remotehost:$remoteport
        iptables -t nat -A POSTROUTING -p tcp -d $remotehost --dport $remoteport -j SNAT --to-source $localIP
        iptables -t nat -A POSTROUTING -p udp -d $remotehost --dport $remoteport -j SNAT --to-source $localIP
    else
        echo 请输入一个IP
        return 1
    fi    
}

rmSnat(){
    local localport=
    echo -n "本地端口号:" ;read localport
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] &&rmIptablesNat $localport
}



echo  -e "${red}你要做什么呢（请输入数字）？Ctrl+C 退出本脚本${black}"
select todo in 增加到域名的转发 删除到域名的转发 增加到IP的转发 删除到IP的转发 列出所有到域名的转发 查看iptables转发规则
do
    case $todo in
    增加到域名的转发)
        addDnat
        break
        ;;
    删除到域名的转发)
        rmDnat
        break
        ;;
    增加到IP的转发)
        addSnat
        break
        ;;
    删除到IP的转发)
        rmSnat
        break
        ;;
    列出所有到域名的转发)
        lsDnat
        ;;
    查看iptables转发规则)
        echo "###########################################################"
        iptables -L PREROUTING -n -t nat --line-number
        iptables -L POSTROUTING -n -t nat --line-number
        echo "###########################################################"
        ;;
    *)
        echo "如果要退出，请按Ctrl+C"
        ;;
    esac
done