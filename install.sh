ipaddr=$(hostname -I)

yum -y install nano zip unzip wget epel-release
#Remi repository
#nginx repository
echo "install nginx-----------------------------------------------------"
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum install yum-utils -y
yum install -y nginx
yum-config-manager --enable remi-php72
#yum --enablerepo=remi,remi-php72 install -y nginx php-fpm php-common
#yum --enablerepo=remi,remi-php72 install -y php-opcache php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-gd php-mbstring php-mcrypt php-xml
yum install -y php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-mbstring php-xml php-pdo php-pear
service httpd stop
service nginx start
service php-fpm start
chkconfig httpd off
chkconfig --add nginx
chkconfig --levels 235 nginx on
chkconfig --add php-fpm
chkconfig --levels 235 php-fpm on
#copy nginx default confd
yes | cp -rf /install/nginx/default.conf /etc/nginx/conf.d/default.conf
sed -i "example.com = $ipaddr" /etc/nginx/conf.d/default.conf
#end file content
service nginx restart
#thay group = nginx;user=nginx
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf

yum update -y
echo "Cai MariaDB-----------------------------------------------------"
#cai mariadb link sau https://www.tecmint.com/install-mariadb-in-centos-6/
yes | cp -rf /install/mysql/mariadb.repo /etc/yum.repos.d/MariaDB.repo
#cai dependencies
yum install boost-devel -y
yum install -y mariadb mariadb-server
service mysql start
chkconfig --levels 235 mysql on
/usr/bin/mysql_secure_installation

#cai phpmyadmin
mkdir /home/pma1
yes | cp -rf /install/phpmyadmin.zip /home/pma1
unzip /home/pma1/phpmyadmin.zip
mv /home/phpmyadmin/* /home/pma1/
#thay doi noi luu session trong /etc/php.ini
	
#sua lai permission
find /var/lib/php/session -type d -exec chmod 755 {} \
setfacl -dm u::rwx,g::rwx,o::r /var/lib/php/session
#tat SELinux o folder cai web
chcon -Rt httpd_sys_content_t /home
#cho phep public user đọc ghi file
chown -R nginx:nginx /home

#Lưu ý: nếu bạn truy cập thẳng vào IP mà báo lỗi không kết nối được thì hãy open port http:
service iptables start
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
service iptables save
service iptables restart
echo "End config iptable";

#--------backup
echo "install rclone"
#64bit
cd /root/
#wget http://downloads.rclone.org/rclone-current-linux-amd64.zip
#unzip rclone-current-linux-amd64.zip
#\cp rclone-current-linux-amd64/rclone /usr/sbin/
#rm -rf rclone-*
#32bit
cd /root/
wget http://downloads.rclone.org/rclone-current-linux-386.zip
unzip rclone-current-linux-386.zip
\cp rclone-v*-linux-386/rclone /usr/sbin/
rm -rf rclone-*

rclone config
#n
#dat ten la remote
#nhan 11 de chon google driver
#enter 2 lan bo qua cai dat client_id va secret
#nhan n de manual config -> copy link nhan token
#copy file backup.sh sang
cp /install/backup.sh /root/backup.sh
#chay /root/backup.sh de test
#down ve rclone copy "remote:/BACKUP_US_1/2017-12-10" /root/
chmod +x /root/backup.sh
EDITOR=nano crontab -e
0 2 * * * /root/backup.sh > /dev/null 2>&1
#chay thu /root/backup.sh
	#nếu file bị lỗi thì mở file sh đó ra bằng
	#vi /root/backup.sh
	#nhấn esc để mở chế độ command rồi gõ
	#:set fileformat=unix
	#:wq!
#----------end backup

#doi port login ssh
#vi /etc/ssh/sshd_config
echo "Port 2124" >> /etc/ssh/sshd_config
# Add the following code to either the top or the bottom of the configuration file. "Port 2124"
iptables -I INPUT -p tcp --dport 2124 --syn -j ACCEPT
service iptables save
yum -y hatprovides /usr/sbin/semanage
yum -y install policycoreutils-python
semanage port -a -t ssh_port_t -p tcp 2124
service sshd restart

#cai gui mail
echo "cai gui mail"
chmod 1777 /var/mail
chmod 1777 /var/tmp
setsebool -P httpd_can_sendmail=on

#insall rar optional
#wget https://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
#tar -zxvf rarlinux-x64-5.5.0.tar.gz
#cd rar
#sudo cp -v rar unrar /usr/local/bin/

