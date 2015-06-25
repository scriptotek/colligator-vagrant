
## Colligator Vagrant box

*Optional*: To speed up [composer package installation](https://blog.viaduct.io/composer-github-api/),
[create a GitHub Personal Access Token](https://github.com/settings/tokens/new)
(access scope: public_repo), and store it a plain text file `github_token`
in the `provision` directory.

    git clone git@github.com:scriptotek/colligator-frontend.git
    git clone git@github.com:scriptotek/colligator-backend.git
    vagrant up

should bring up a Ubuntu dev server on http://172.28.128.9/
with Nginx, PHP 5.5, MySQL and ElasticSearch installed.

Use `vagrant ssh` to SSH into the box. You'll find

* `colligator-frontend` mounted at `/var/www/frontend`
* `colligator-backend` mounted at `/var/www/backend`

Nginx setup:

* `/api` → `/var/www/backend/public`
* `/` → `/var/www/frontend`

Open ports:

* 80 http
* 3306 mysql
* 9200 elasticsearch

Debugging tips:

* nginx logs are at `/var/log/nginx`, php log at `/var/log/php5-fpm.log`
