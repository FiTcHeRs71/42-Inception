#!/bin/bash

# Partie 1 : installer wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Partie 2 : télécharger et configurer WordPress
cd /var/www/html

# Attendre que MariaDB soit prête à accepter les connexions
until mariadb -h mariadb -u $MYSQL_USER -p"$(cat /run/secrets/db_password)" -e "SELECT 1;" &>/dev/null; do
	echo "En attente de MariaDB..."
	sleep 2
done

if [ ! -f "wp-config.php" ]; then

	DB_PASSWORD=$(cat /run/secrets/db_password)
	ADMIN_PASSWORD=$(cat /run/secrets/credentials)
	WP_USER_PASSWORD=$(cat /run/secrets/visitor)

	wp core download --allow-root

	wp config create \
		--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$DB_PASSWORD \
		--dbhost=mariadb:3306 \
		--allow-root

	wp core install \
		--url=$DOMAIN_NAME \
		--title="Inception" \
		--admin_user=$WP_ADMIN_USER \
		--admin_password=$ADMIN_PASSWORD \
		--admin_email=$WP_ADMIN_EMAIL \
		--allow-root

	wp user create $WP_USER $WP_USER_EMAIL \
		--role=author \
		--user_pass=$WP_USER_PASSWORD \
		--allow-root

fi

sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

exec /usr/sbin/php-fpm8.2 -F