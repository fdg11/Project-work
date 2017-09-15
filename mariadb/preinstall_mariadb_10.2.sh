#!/usr/bin/env bash

echo ">>> Installing MariaDB"

# [[ -z $1 ]] && { echo "!!! MariaDB root password not set"; exit 1; }

# VALUE
MARIADB_VERSION='10.2'
PASSWD="Qwerty23"

# Import repo key
apt-get install software-properties-common -y
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

# Add repo for MariaDB
add-apt-repository "deb [arch=amd64,i386] http://mirrors.accretive-networks.net/mariadb/repo/$MARIADB_VERSION/ubuntu xenial main"

# Update
apt-get update

# Install MariaDB without password prompt
debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $PASSWD"
debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $PASSWD"

# Install MariaDB
apt-get install -qq mariadb-server

# Create database "wordpress"
MYSQL=`which mysql`
SQL_DATA="CREATE database wordpress;"
$MYSQL -uroot -p$PASSWD -e "$SQL_DATA"

# Make Maria connectable from outside world 
if [ "$1" = "true" ]; then
	# enable remote access
	# setting the mysql bind-address to allow connections from everywhere
	sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

	# adding grant privileges to mysql root user from everywhere
	Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;"
	Q2="FLUSH PRIVILEGES;"
	SQL="${Q1}${Q2}"

	$MYSQL -uroot -p$PASSWD -e "$SQL"

	systemctl restart mysql 
fi


