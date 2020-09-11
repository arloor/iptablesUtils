#! /bin/bash
[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;



base=/etc/dnat
mkdir $base 2>/dev/null
conf=$base/conf
firstAfterBoot=1
lastConfig="/iptables_nat.sh"
lastConfigTmp="/iptables_nat.sh_tmp"


####
echo "正在安装依赖...."
yum install -y bind-utils &> /dev/null
apt install -y dnsutils &> /dev/null
echo "Completed：依赖安装完毕"
echo ""
####
turnOnNat(){
    # 开启端口转发
    echo "1. 端口转发开启  【成功】"
    sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
    if [ $? -ne 0 ]; then
        echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
    fi

    #开放FORWARD链
    echo "2. 开放iptbales中的FORWARD链  【成功】"
    arr1=(`iptables -L FORWARD -n  --line-number |grep "REJECT"|grep "0.0.0.0/0"|sort -r|awk '{print $1,$2,$5}'|tr " " ":"|tr "\n" " "`)  #16:REJECT:0.0.0.0/0 15:REJECT:0.0.0.0/0
    for cell in ${arr1[@]}
    do
        arr2=(`echo $cell|tr ":" " "`)  #arr2=16 REJECT 0.0.0.0/0
        index=${arr2[0]}
        echo 删除禁止FOWARD的规则——$index
        iptables -D FORWARD $index
    done
    iptables --policy FORWARD ACCEPT
}
turnOnNat



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

dnat(){
     [ "$#" = "3" ]&&{
        local localport=$1
        local remote=$2
        local remoteport=$3

        cat >> $lastConfigTmp <<EOF
iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A PREROUTING -p udp --dport $localport -j DNAT --to-destination $remote:$remoteport
iptables -t nat -A POSTROUTING -p tcp -d $remote --dport $remoteport -j SNAT --to-source $localIP
iptables -t nat -A POSTROUTING -p udp -d $remote --dport $remoteport -j SNAT --to-source $localIP
EOF
    }
}

dnatIfNeed(){
  [ "$#" = "3" ]&&{
    local needNat=0
    local remote=$(host -t a  $2|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1)
    if [ "$remote" = "" ];then
            echo Warn:解析失败
          return 1;
     fi
  }||{
      echo "Error: host命令缺失或传递的参数数量有误"
      return 1;
  }
    echo $remote >$base/${1}IP
    dnat $1 $remote $3
}


echo "3. 开始监听域名解析变化"
echo ""
while true ;
do
## 获取本机地址
localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "${localIP}" = "" ]; then
        localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1|head -n 1 )
fi
echo  "本机网卡IP [$localIP]"
cat > $lastConfigTmp <<EOF
iptables -t nat -F PREROUTING
iptables -t nat -F POSTROUTING
EOF
arr1=(`cat $conf`)
for cell in ${arr1[@]}  
do
    arr2=(`echo $cell|tr ":" " "|tr ">" " "`)  #arr2=16 REJECT 0.0.0.0/0
    # 过滤非法的行
    [ "${arr2[2]}" != "" -a "${arr2[3]}" = "" ]&& testVars ${arr2[0]}  ${arr2[1]} ${arr2[2]}&&{
        echo "转发规则： ${arr2[0]} => ${arr2[1]}:${arr2[2]}"
        dnatIfNeed ${arr2[0]} ${arr2[1]} ${arr2[2]}
    }
done

lastConfigTmpStr=`cat $lastConfigTmp`
lastConfigStr=`cat $lastConfig`
if [ "$firstAfterBoot" = "1" -o "$lastConfigTmpStr" != "$lastConfigStr" ];then
    echo '更新iptables规则[DOING]'
    source $lastConfigTmp
    cat $lastConfigTmp > $lastConfig
    echo '更新iptables规则[DONE]，新规则如下：'
    echo "###########################################################"
    iptables -L PREROUTING -n -t nat --line-number
    iptables -L POSTROUTING -n -t nat --line-number
    echo "###########################################################"
else
 echo "iptables规则未变更"
fi

firstAfterBoot=0
echo '' > $lastConfigTmp
sleep 60
echo ''
echo ''
echo ''
done
