#!/bin/bash

if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
	cat > /tmp/init.sql <<EOF
CREATE DATABASE $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
else
	echo "Database already exists"
fi

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

exec mariadbd --init-file=/tmp/init.sql --user=mysql