#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

DB_ROOT_PWD="root"

die() {
    echo "FATAL ERROR: $* (status $?)" 1>&2
    exit 1
}

#ls colligator-frontend > /dev/null || die "Did you forget to clone colligator-frontend? See readme.md"
#ls colligator-backend > /dev/null || die "Did you forget to clone colligator-backend? See readme.md"

#-------------------------------------------------------------------------
# GitHub
#-------------------------------------------------------------------------

cd /provision
GITHUB_KEY="$( cat github_token 2>/dev/null | xargs )"
test -z "$GITHUB_KEY" && die "No GitHub key provided. Please create a file 'github_token'."

mkdir -p /root/.composer && echo "{ \"github-oauth\": { \"github.com\": \"$GITHUB_KEY\" } }" >| /root/.composer/auth.json || die
mkdir -p /home/vagrant/.composer/ && echo "{ \"github-oauth\": { \"github.com\": \"$GITHUB_KEY\" } }" >| /home/vagrant/.composer/auth.json || die
chown vagrant:vagrant /home/vagrant/.composer/auth.json

#-------------------------------------------------------------------------
# Install and configure PHP, NodeJS, Nginx, ...
#-------------------------------------------------------------------------

echo ">>> Configuring locales <<<"
dpkg-reconfigure locales > /dev/null || die

echo ">>> Installing packages <<<"
hash npm 2>/dev/null || {
	curl -sL https://deb.nodesource.com/setup | bash - || die "Failed to add nodesource"
	apt-get install -y nodejs || die
}
hash bower 2>/dev/null || {
	npm install -g bower
}

apt-get install -y build-essential libssl-dev git nginx php5-fpm php5-cli php5-mcrypt php5-imagick php5-curl || die
# mcrypt needs to be manually enabled
ln -sf /etc/php5/mods-available/mcrypt.ini /etc/php5/fpm/conf.d/20-mcrypt.ini
ln -sf /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini

hash rvm 2>/dev/null || {
	echo ">>> Installing Ruby <<<"
	gpg --quiet --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	\curl -sSL https://get.rvm.io | bash -s stable --quiet-curl
	. /etc/profile.d/rvm.sh
	rvm reload
	rvm requirements run --quiet-curl || die
	rvm install 2.2.1 --quiet-curl || die "Failed to install Ruby" # `rvm list remote` to see which binary rubies are available
	rvm --default use 2.2.1
}

hash composer 2>/dev/null || {
	echo ">>> Installing Composer <<<"
	curl -sS https://getcomposer.org/installer | php > /dev/null
	chmod +x composer.phar
	mv composer.phar /usr/local/bin/composer
}

echo "Updating Composer..."
composer self-update

echo "Configuring Nginx"
if [[ ! -e /etc/nginx/server.key ]]; then
	echo "Generate Nginx server private key..."
	genrsa="$(openssl genrsa -out /etc/nginx/server.key 2048 2>&1)"
	echo $genrsa
fi
if [[ ! -e /etc/nginx/server.csr ]]; then
	echo "Generate Certificate Signing Request (CSR)..."
	openssl req -new -batch -key /etc/nginx/server.key -out /etc/nginx/server.csr
fi
if [[ ! -e /etc/nginx/server.crt ]]; then
	echo "Sign the certificate using the above private key and CSR..."
	signcert="$(openssl x509 -req -days 365 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>&1)"
	echo $signcert
fi

# Enable nginx site
cp /provision/nginx_vhost /etc/nginx/sites-available/nginx_vhost
ln -sf /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Since we cannot chmod in a synced folder, we just change the Nginx user
# from 'www-data' to 'vagrant' instead.
sed -i 's/user = www-data/user = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php5/fpm/pool.d/www.conf

#if [[ ! -d /var/www/html/ ]]; then
#	mkdir -p /var/www/html/
#fi

# echo "COLLIGATOR says hello. Looking for <a href='/collections/42'>42</a>?" >| /var/www/html/index.html

echo "Restarting Nginx and PHP-FPM"
service nginx restart > /dev/null
service php5-fpm restart > /dev/null


#-------------------------------------------------------------------------
# MySQL
#-------------------------------------------------------------------------

hash mysql 2>/dev/null || {

	debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password password $DB_ROOT_PWD"
	debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password_again password $DB_ROOT_PWD"

	apt-get install -y mysql-server-5.6 || die "Failed to install MariaDB"
	sed -ri "s/^#?bind-address.*$/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

mysql --user="root" --password="$DB_ROOT_PWD" -t <<EOF
CREATE DATABASE IF NOT EXISTS colligator;
CREATE USER 'colligator'@'%' IDENTIFIED BY 'colligator';
GRANT ALL ON colligator.* TO 'colligator'@'%';
FLUSH PRIVILEGES;
EOF

	service mysql restart

	echo ----------------------------------------------------------------
	echo MySQL root password: $DB_ROOT_PWD
	echo ----------------------------------------------------------------
}

#-------------------------------------------------------------------------
# Frontend
#-------------------------------------------------------------------------

cd /var/www/frontend || die

npm config set spin false
npm config set loglevel warn
echo "Frontend: Installing npm packages"
npm install
echo "Frontend: Installing bower packages"
bower install --config.interactive=false --allow-root

#-------------------------------------------------------------------------
# Backend
#-------------------------------------------------------------------------

cd /var/www/backend || die
if [[ ! -f composer.lock ]]; then
	echo "Backend: Installing Composer packages"
	composer install --no-progress --prefer-dist
	cp .env.example .env
	php artisan key:generate
	echo ----------------------------------------------------------------
	echo Copied '.env.example' to '.env'. You might want to modify it...
	echo ----------------------------------------------------------------
# else
	# echo "Backend: Updating Composer packages"
	# composer update --no-progress --prefer-dist
fi
