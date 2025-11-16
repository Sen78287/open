#!/bin/bash
#删除原来的脚本文件
rm -rf $0
echo 
echo -e "\033[35m 程序载入中，请稍后... \033[0m"
if [ ! -e "/dev/net/tun" ];
    then
	    echo -e "\e[31m 安装被终止！ \e[0m"
		echo -e "\e[31m TUN/TAP网卡未开启，请联系服务商开启TUN/TAP \e[0m"
        exit 0;
	else
		echo -e "\e[31m 网卡状态[  OK  ] \e[0m"
fi

#全局定义
folder='OpenVPN'
mirrorHost='https://github.com/Sen78287/open.git'
ipAddress=`curl -s http://members.3322.org/dyndns/getip`;
pass=`wget https://github.com/Sen78287/open.git/pass.php -O - -q ; echo`;

welcome='
==================================================================
                                                                           
                     ☆-妖火流控--复活版
                     ☆-https://yaohuo.me
               支持常规模式，HTTP转接，UDP53端口   
			   
=================================================================='
errorLogo='
==================================================================

					 ☆-妖火流控--复活版	
					 ☆-😂 安装出错了
					 
=================================================================='

##################################################

#更换阿里云源
echo -e "\033[35m 正在更换阿里云源... \033[0m"
yum -y install epel-release wget >/dev/null 2>&1
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/repo/epel-7.repo >/dev/null 2>&1
yum clean all >/dev/null 2>&1
yum makecache
echo -e "\033[35m 更换阿里云源完成！ \033[0m"

#验证IP地址是否配置正确
function InputIPAddress()
{
	if [ "$ipAddress" == '' ]; then
		echo ' 无法检测您的IP';
		read -p ' 请输入您的公网IP:' ipAddress;
		[ "$ipAddress" == '' ] && InputIPAddress;
	fi;
	[ "$ipAddress" != '' ] && echo -n '[  OK  ] 您的IP是:' && echo $ipAddress;
	sleep 2
}



#定义后台管理员密码
read -p " 请输入后台管理员密码：" adminPass
if [ -z $adminPass ]
	then
		read -p " 后台管理员密码不能为空，请重新输入：" adminPass
fi


#定义MriaDB数据库密码
read -p " 请输入数据库密码：" mySqlPass
if [ -z $mySqlPass ]
	then
		read -p " 密码不能为空，请重新输入：" mySqlPass
fi

echo -e "\033[35m 正在清理安装环境... \033[0m"
systemctl stop openvpn@server* >/dev/null 2>&1
systemctl stop squid >/dev/null 2>&1
killall openvpn >/dev/null 2>&1
killall squid >/dev/null 2>&1
systemctl stop httpd >/dev/null 2>&1
systemctl stop mariadb >/dev/null 2>&1
systemctl stop mysqld >/dev/null 2>&1
yum remove -y openvpn squid >/dev/null 2>&1
yum remove -y httpd >/dev/null 2>&1
yum remove -y nginx >/dev/null 2>&1
yum remove -y mariadb mariadb-server >/dev/null 2>&1
yum remove -y mysql mysql-server >/dev/null 2>&1
yum remove -y php-fpm php-cli php-gd php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-devel php-xml >/dev/null 2>&1
rm -rf /etc/openvpn/* >/dev/null 2>&1
rm -rf /etc/squid/* >/dev/null 2>&1
rm -rf /bin/mproxy >/dev/null 2>&1
rm -rf /var/www/* >/dev/null 2>&1
rm -rf /home/OpenVPN-YHML.tar.gz >/dev/null 2>&1

echo -e "\033[35m 正在配置网络环境... \033[0m"
sleep 2
systemctl stop firewalld >/dev/null 2>&1
systemctl disable firewalld >/dev/null 2>&1
yum install iptables -y >/dev/null 2>&1
systemctl start iptables >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j MASQUERADE >/dev/null 2>&1
iptables -t nat -A POSTROUTING -s 10.5.0.0/16 -o eth0 -j MASQUERADE >/dev/null 2>&1
iptables -t nat -A POSTROUTING -s 10.6.0.0/16 -o eth0 -j MASQUERADE >/dev/null 2>&1
iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -o eth0 -j MASQUERADE >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 443 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 80 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 8080 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 666 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 3306 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p TCP --dport 22 -j ACCEPT >/dev/null 2>&1
iptables -A INPUT -p udp --dport 53 -j ACCEPT >/dev/null 2>&1
iptables -t nat -A POSTROUTING -j MASQUERADE >/dev/null 2>&1
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT >/dev/null 2>&1
systemctl restart iptables >/dev/null 2>&1
systemctl enable iptables >/dev/null 2>&1
#开启转发以及优化网络
sleep 2
cd /etc
rm -rf sysctl.conf
wget ${mirrorHost}/${folder}/sysctl.conf >/dev/null 2>&1
sleep 2
chmod 777 /etc/sysctl.conf
sysctl -p >/dev/null 2>&1

echo -e "\033[35m 正在关闭SELINUX... \033[0m"
##关闭selinux
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config  && setenforce 0  

###########################################################################################################################3
#安装openvpn
yum makecache >/dev/null 2>&1
yum install -y openvpn >/dev/null 2>&1
yum install -y openssl openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig curl tar expect unzip >/dev/null 2>&1
rpm -Uvh --oldpackage ${mirrorHost}/${folder}/openvpn-2.3.12-1.el7.x86_64.rpm
sleep 2
cd /etc/openvpn
wget ${mirrorHost}/${folder}/EasyRSA.tar.gz >/dev/null 2>&1
wget ${mirrorHost}/${folder}/peizhi.cfg >/dev/null 2>&1
wget ${mirrorHost}/${folder}/server-passwd.tar.gz >/dev/null 2>&1
sleep 2
tar -zxvf EasyRSA.tar.gz >/dev/null 2>&1
sleep 2
cd /etc/openvpn/easy-rsa/
source vars >/dev/null 2>&1
./clean-all >/dev/null 2>&1
sleep 2
echo -e "\033[35m 正在生成CA/服务端证书... \033[0m"
./ca && ./centos centos
echo -e "\033[35m 正在生成TLS密钥... \033[0m"
sleep 2
openvpn --genkey --secret ta.key
echo -e "\033[35m 正在生成SSL加密证书，这是一个漫长的等待过程... \033[0m"
sleep 2
./build-dh

###################################################
sleep 2
cd /etc/openvpn
tar -zxvf server-passwd.tar.gz >/dev/null 2>&1
sleep 2
sed -i "s/MySQLPass/$mySqlPass/g" /etc/openvpn/disconnect.sh 
sed -i "s/MySQLPass/$mySqlPass/g" /etc/openvpn/login.sh
sed -i "s/MySQLPass/$mySqlPass/g" /etc/openvpn/peizhi.cfg
rm -rf server-passwd.tar.gz
rm -rf EasyRSA.tar.gz
sleep 2

#OpenVPN监听UDP53端口
echo '#########################################
#             OpenVPN                   #
#                                       #
#########################################
port 53
proto udp
dev tun
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/centos.crt
key /etc/openvpn/easy-rsa/keys/centos.key
dh /etc/openvpn/easy-rsa/keys/dh2048.pem
auth-user-pass-verify /etc/openvpn/login.sh via-env
client-disconnect /etc/openvpn/disconnect.sh
client-connect /etc/openvpn/connect.sh
client-cert-not-required
username-as-common-name
script-security 3 system
server 10.6.0.0 255.255.0.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 114.114.114.114"
push "dhcp-option DNS 114.114.115.115"
keepalive 10 120
tls-auth /etc/openvpn/easy-rsa/ta.key 0  
comp-lzo
persist-key
persist-tun
status /var/www/html/res/openvpn-udp.txt
log         openvpn-udp53.log
log-append  openvpn-udp53.log
verb 3' >/etc/openvpn/server-udp53.conf
#更改openvpn文件权限
chmod -R 0777 /etc/openvpn

########################################################################################################
#安装squid
sleep 2
yum install -y squid
cd /etc/squid
wget ${mirrorHost}/${folder}/squid.conf
wget ${mirrorHost}/${folder}/auth_user
chmod 777 squid.conf auth_user
squid -z

#安装mproxy
cd /bin
wget ${mirrorHost}/${folder}/mproxy
chmod  777 mproxy
############################################
echo -e "\033[35m 正在写入快捷命令... \033[0m"
wget ${mirrorHost}/${folder}/YHML
chmod 777 /bin/YHML
echo "sh /bin/YHML" >>/etc/rc.d/rc.local
chmod 777 /etc/rc.d/rc.local
sleep 2

#配置web面板采用apache+mariadb架构
echo -e "\033[35m 正在安装WEB面板... \033[0m"
yum  install -y httpd php php-mysql php-gd >/dev/null 2>&1
sed -i 's/#ServerName www.example.com:80/ServerName www.example.com:666/g' /etc/httpd/conf/httpd.conf
sed -i 's/Listen 80/Listen 666/g' /etc/httpd/conf/httpd.conf
systemctl start httpd
systemctl enable httpd >/dev/null 2>&1
####
sleep 1
yum -y install mariadb mariadb-server >/dev/null 2>&1
systemctl start mariadb
systemctl enable mariadb >/dev/null 2>&1
#mysql初始化
/usr/bin/expect << EOF
spawn mysql_secure_installation
	expect {
        "Enter current password for root (enter for none):" {send "\r";exp_continue} 
        "Set root password?" {send "Y\r";exp_continue}
        "New password" {send "$mySqlPass\r";exp_continue}
        "Re-enter new password" {send "$mySqlPass\r";exp_continue}       
        "Remove anonymous users?" {send "Y\r";exp_continue}
        "Disallow root login remotely?" {send "Y\r";exp_continue}
        "Remove test database and access to it?" {send "Y\r";exp_continue}
        "Reload privilege tables now?" {send "Y\r";exp_continue}
        }
	expect eof
EOF
sleep 1
echo -e "\033[35m 正在配置WEB流控... \033[0m"
cd /var
wget ${mirrorHost}/${folder}/web.tar.gz >/dev/null 2>&1
tar -zxvf web.tar.gz >/dev/null 2>&1
cd /var/www
mysql -uroot -p$mySqlPass -e"CREATE DATABASE ov;"
mysql -uroot -p$mySqlPass ov < ov.sql
rm -f ov.sql
sed -i "s/MySQLPass/$mySqlPass/g" /var/www/html/config.php >/dev/null 2>&1
sed -i "s/SuperPass/$adminPass/g" /var/www/html/config.php >/dev/null 2>&1
cd /var/www/html/res/
rm -rf jiankong
wget ${mirrorHost}/${folder}/jiankong >/dev/null 2>&1
chmod -R 0777 /var/www/html
rm -rf web.tar.gz
echo -e "\033[35m WEB流控部署完成~~~~ \033[0m"
sleep 2
#######################################################################
echo -e "\033[35m 正在启动Squid服务... \033[0m"
systemctl start squid
systemctl enable squid >/dev/null 2>&1
sleep 2
echo -e "\033[35m 正在启动mproxy服务... \033[0m"
./mproxy -l 8080 -d >/dev/null 2>&1
sleep 2
echo -e "\033[35m 正在OpenVPN启动服务... \033[0m"
systemctl enable openvpn@server >/dev/null 2>&1
systemctl enable openvpn@server-udp53 >/dev/null 2>&1
systemctl start openvpn@server
systemctl start openvpn@server-udp53
sleep 2
#######################################################################

#######################生成配置文件
sleep 2
cp /etc/openvpn/easy-rsa/keys/ca.crt /home/ >/dev/null 2>&1
cp /etc/openvpn/easy-rsa/ta.key /home/ >/dev/null 2>&1
cd /home/ >/dev/null 2>&1
########################################################################

echo -e "\033[35m 正在生成OpenVPN配置文件... \033[0m"

echo '# 本文件由系统自动生成
# HTTP转接模式
setenv IV_GUI_VER "de.blinkt.openvpn 0.6.17" 
machine-readable-output
client
dev tun
proto tcp
connect-retry-max 5
connect-retry 5
resolv-retry 60
########免流代码########
remote wap.17wo.cn 80
http-proxy-option EXT1 POST http://wap.17wo.cn
http-proxy-option EXT1 Host wap.17wo.cn' >op-http-1.ovpn
echo "http-proxy $ipAddress 8080
########################
########Squid认证#######
<http-proxy-user-pass>
root
YHML
</http-proxy-user-pass>
resolv-retry infinite
nobind
persist-key
persist-tun
push route 114.114.114.144 114.114.115.115
##CA证书
<ca>
`cat ca.crt`
</ca>
key-direction 1
####TLS密钥
<tls-auth>
`cat ta.key`
</tls-auth>
auth-user-pass
ns-cert-type server
comp-lzo
verb 3
">op-http-2.ovpn
cat op-http-1.ovpn op-http-2.ovpn>OpenVPN-HTTP.ovpn
sleep 2
rm -rf op-http-1.ovpn op-http-2.ovpn


####################################################
sleep 2
echo '# 本文件由系统自动生成
# 常规模式
setenv IV_GUI_VER "de.blinkt.openvpn 0.6.17" 
machine-readable-output
client
dev tun
proto tcp
connect-retry-max 5
connect-retry 5
resolv-retry 60
########免流代码########
http-proxy-option EXT1 "POST http://wap.10010.com" 
http-proxy-option EXT1 "GET http://wap.10010.com" 
http-proxy-option EXT1 "X-Online-Host: wap.10010.com" 
http-proxy-option EXT1 "POST http://wap.10010.com" 
http-proxy-option EXT1 "X-Online-Host: wap.10010.com" 
http-proxy-option EXT1 "POST http://wap.10010.com" 
http-proxy-option EXT1 "Host: wap.10010.com" 
http-proxy-option EXT1 "GET http://wap.10010.com" 
http-proxy-option EXT1 "Host: wap.10010.com"' >op-lt-1.ovpn
echo "remote $ipAddress 443
http-proxy $ipAddress 80
########################" >op-lt-2.ovpn
echo "########Squid认证#######
<http-proxy-user-pass>
root
YHML
</http-proxy-user-pass>
resolv-retry infinite
nobind
persist-key
persist-tun
push route 114.114.114.144 114.114.115.115
##CA证书
<ca>
`cat ca.crt`
</ca>
key-direction 1
####TLS密钥
<tls-auth>
`cat ta.key`
</tls-auth>
auth-user-pass
ns-cert-type server
comp-lzo
verb 3
">op-lt-3.ovpn
cat op-lt-1.ovpn op-lt-2.ovpn op-lt-3.ovpn>OpenVPN.ovpn
sleep 2
rm -rf op-lt-1.ovpn op-lt-2.ovpn op-lt-3.ovpn
#############################################################
sleep 2
echo '# 本文件由系统自动生成
# UDP模式
setenv IV_GUI_VER "de.blinkt.openvpn 0.6.17" 
machine-readable-output
client
dev tun
proto udp
connect-retry-max 5
connect-retry 5
resolv-retry 60
########免流代码########'>op-udp53-1.ovpn
echo "remote $ipAddress 53
########################">op-udp53-2.ovpn
echo "########Squid认证#######
<http-proxy-user-pass>
root
YHML
</http-proxy-user-pass>
resolv-retry infinite
nobind
persist-key
persist-tun
push route 114.114.114.144 114.114.115.115
##CA证书
<ca>
`cat ca.crt`
</ca>
key-direction 1
####TLS密钥
<tls-auth>
`cat ta.key`
</tls-auth>
auth-user-pass
ns-cert-type server
comp-lzo
verb 3
">op-udp53-3.ovpn
cat op-udp53-1.ovpn op-udp53-2.ovpn op-udp53-3.ovpn>OpenVPN-UDP53.ovpn
sleep 2
rm -rf op-udp53-1.ovpn op-udp53-2.ovpn op-udp53-3.ovpn

#########################################################
sleep 1
echo -e "\033[35m 正在打包配置文件... \033[0m"
tar -zcvf OpenVPN-YHML.tar.gz ./{OpenVPN-HTTP.ovpn,OpenVPN.ovpn,OpenVPN-UDP53.ovpn,ca.crt,ta.key} >/dev/null 2>&1
sleep 2
cp OpenVPN-YHML.tar.gz /var/www/html 
rm -rf ca.crt ta.key OpenVPN-YHML.tar.gz OpenVPN-HTTP.ovpn OpenVPN.ovpn OpenVPN-UDP53.ovpn
clear
#######安装结束
echo "
===============================================================================
    重启命令————YHML                                                         
    
    控制面板为 http://$ipAddress:666 管理后台为 http://$ipAddress:666/admin  
                                                                             
    配置文件下载地址 http://$ipAddress:666/OpenVPN-YHML.tar.gz               
                                                                             
    管理账号 admin————密码 $adminPass 

    欢迎访问官网论坛：www.yaohuo.me—妖火网-分享你我
==============================================================================="
exit 0
