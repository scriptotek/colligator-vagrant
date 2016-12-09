#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Edit the following to change the name of the database user that will be created:
APP_DB_USER=colligator
APP_DB_PASS=colligator

# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=$APP_DB_USER

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.6

# ###########################################################

die() {
    echo "FATAL ERROR: $* (status $?)" 1>&2
    exit 1
}

ls /var/www/frontend > /dev/null || die "Did you forget to clone colligator-frontend? See readme.md"
ls /var/www/backend > /dev/null || die "Did you forget to clone colligator-backend? See readme.md"

yum -y update

curl 'https://setup.ius.io/' -o setup-ius.sh
bash setup-ius.sh

yum install -y vim \
   nodejs \
   wget \
   httpd \
   mod_ssl \
   php70u-cli \
   php70u-fpm \
   php70u-mbstring \
   php70u-imagick \
   php70u-pgsql \
   php70u-pdo \
   php70u-json \
   java-1.8.0-openjdk


# MOTD
cp -f /provision/motd.sh /etc/profile.d/motd.sh


# PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
# if [ ! -f "$PG_REPO_APT_SOURCE" ]
# then
#   # Add PG apt repo:
#   echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

#   # Add PGDG repo key:
#   wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
# fi


# apt-get update
# #-------------------------------------------------------------------------
# # Install and configure PHP, NodeJS, Apache, ...
# #-------------------------------------------------------------------------

# echo ">>> Configuring locales <<<"
# dpkg-reconfigure locales > /dev/null || die

# echo ">>> Installing packages <<<"

# apt-get install -y build-essential \
#     tcl \
#     libssl-dev \
#     apache2 \
#     nodejs \
#     nodejs-legacy \
#     php-fpm \
#     php-cli \
#     php-mbstring \
#     php-xml \
#     php-imagick \
#     php-curl \
#     default-jre \
#     ntp || die

hash yarn 2>/dev/null || {
	echo ">>> Installing yarn <<<"
	wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo
	yum install -y yarn
}

hash bower 2>/dev/null || {
	yarn global add bower
}

# hash rvm 2>/dev/null || {
# 	echo ">>> Installing Ruby <<<"
# 	gpg --quiet --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
# 	\curl -sSL https://get.rvm.io | bash -s stable --quiet-curl
# 	. /etc/profile.d/rvm.sh
# 	rvm reload
# 	rvm requirements run --quiet-curl || die
# 	rvm install 2.3.3 --quiet-curl || die "Failed to install Ruby" # `rvm list remote` to see which binary rubies are available
# 	rvm --default use 2.3.3
# }

# Composer
hash composer 2>/dev/null || {
	echo ">>> Installing Composer <<<"
	curl -sS https://getcomposer.org/installer | php > /dev/null
	chmod +x composer.phar
	mv composer.phar /usr/bin/composer
}

echo ">>> Updating Composer <<<"
composer self-update


# ElasticSearch
if [[ ! -f /etc/yum.repos.d/elasticsearch.repo ]]; then

	echo ">>> Installing ElasticSearch <<<"
	rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
	cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
EOF

	yum install -y elasticsearch
	systemctl enable elasticsearch
	# update-rc.d elasticsearch defaults 95 10

	sed -ri 's/^#?PID_DIR=\/var\/run\/elasticsearch/PID_DIR=\/var\/run/g' /etc/default/elasticsearch
	sed -i 's/#START_DAEMON/START_DAEMON/' /etc/default/elasticsearch
	systemctl enable elasticsearch
	systemctl restart elasticsearch
fi

# -----------------------------------------------------------------------------

echo ">>> Configuring Apache"

mkdir -p /etc/apache2/ssl
if [[ ! -e /etc/apache2/ssl/server.key ]]; then
	echo "Generate Apache server private key..."
	genrsa="$(openssl genrsa -out /etc/apache2/ssl/server.key 2048 2>&1)"
	echo $genrsa
fi
if [[ ! -e /etc/apache2/ssl/server.csr ]]; then
	echo "Generate Certificate Signing Request (CSR)..."
	openssl req -new -batch -key /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.csr
fi
if [[ ! -e /etc/apache2/ssl/server.crt ]]; then
	echo "Sign the certificate using the above private key and CSR..."
	signcert="$(openssl x509 -req -days 365 -in /etc/apache2/ssl/server.csr -signkey /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.crt 2>&1)"
	echo $signcert
fi

cp /provision/colligator.conf /etc/httpd/conf.d/colligator.conf

systemctl enable apache2
systemctl enable php-fpm

# ln -sf /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/
# rm -f /etc/nginx/sites-enabled/default

# Since we cannot chmod in a synced folder, we just change the Nginx user
# from 'php-fpm' to 'vagrant' instead.
sed -i 's/user = php-fpm/user = vagrant/g' /etc/php-fpm.d/www.conf
sed -i 's/group = php-fpm/group = vagrant/g' /etc/php-fpm.d/www.conf

sed -i 's/display_errors = Off/display_errors = On/' /etc/php.ini
sed -i 's/display_startup_errors = Off/display_startup_errors = On/' /etc/php.ini

# #if [[ ! -d /var/www/html/ ]]; then
# #	mkdir -p /var/www/html/
# #fi

echo "COLLIGATOR says hello. Looking for <a href='/colligator/collections/42'>42</a>?" >| /var/www/html/index.html

echo ">>> Restarting Apache and PHP-FPM"
systemctl restart httpd > /dev/null
systemctl restart php-fpm > /dev/null


#-------------------------------------------------------------------------
# Postgres
#-------------------------------------------------------------------------

hash psql 2>/dev/null || {
	yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
	yum install -y postgresql96-server
	systemctl enable postgresql-9.6

	/usr/pgsql-9.6/bin/initdb -D /var/lib/pgsql/9.6/data/ -U postgres

	# PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
	# PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
	# PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# 	# Edit postgresql.conf to change listen address to '*':
# 	sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# 	# Append to pg_hba.conf to add password auth:
# 	echo "host    all             all             all                     md5" >> "$PG_HBA"

# 	# Explicitly set default client_encoding
# 	echo "client_encoding = utf8" >> "$PG_CONF"

	cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF

	systemctl restart postgresql-9.6
}

# #-------------------------------------------------------------------------
# # Frontend
# #-------------------------------------------------------------------------

# cd /var/www/frontend || die

# # npm config set spin false
# # npm config set loglevel warn
# echo "Frontend: Installing npm packages"
# yarn install
# echo "Frontend: Installing bower packages"
# bower install --config.interactive=false --allow-root

# #-------------------------------------------------------------------------
# # Backend
# #-------------------------------------------------------------------------

# cd /var/www/backend || die
# if [[ ! -f composer.lock ]]; then

# 	echo "Backend: Installing Composer packages"

# 	GITHUB_KEY="$( cat /provision/github_token 2>/dev/null | xargs )"
# 	if [[ -z "$GITHUB_KEY" ]]; then
# 		echo --------------------------------------------------------------------
# 		echo No 'github_token' found! Composer package installation will be slow.
# 		echo --------------------------------------------------------------------

# 		composer install --no-progress --no-interaction --prefer-source

# 	else

# 		mkdir -p /root/.composer && echo "{ \"github-oauth\": { \"github.com\": \"$GITHUB_KEY\" } }" >| /root/.composer/auth.json || die
# 		mkdir -p /home/vagrant/.composer/ && echo "{ \"github-oauth\": { \"github.com\": \"$GITHUB_KEY\" } }" >| /home/vagrant/.composer/auth.json || die
# 		chown vagrant:vagrant /home/vagrant/.composer/auth.json

# 		composer install --no-progress --no-interaction --prefer-dist

# 	fi

# 	cp .env.example .env
# 	php artisan key:generate
# 	echo ----------------------------------------------------------------
# 	echo Copied '.env.example' to '.env'. You might want to modify it...
# 	echo ----------------------------------------------------------------
# # else
# 	# echo "Backend: Updating Composer packages"
# 	# composer update --no-progress --prefer-dist
# fi
