
## Colligator Vagrant box

*Optional*: To speed up [composer package installation](https://blog.viaduct.io/composer-github-api/),
[create a GitHub Personal Access Token](https://github.com/settings/tokens/new)
(access scope: public_repo), and store it a plain text file `github_token`
in the `provision` directory.

    git clone git@github.com:scriptotek/colligator-frontend.git
    git clone git@github.com:scriptotek/colligator-backend.git
    git clone git@github.com:scriptotek/colligator-editor.git
    vagrant up

should bring up a Centos 7 dev server on http://172.28.128.9/
with Apache, PHP 7.0, MySQL and ElasticSearch installed.

Use `vagrant ssh` to SSH into the box. You'll find

* `colligator-frontend` mounted at `/var/www/frontend`
* `colligator-backend` mounted at `/var/www/backend`
* `colligator-editor` mounted at `/var/www/editor`

Apache setup:

* `/api` → `/var/www/backend/public`
* `/editor` → `/var/www/editor`
* `/` → `/var/www/frontend`

Open ports:

* 80 http
* 3306 mysql
* 9200 elasticsearch

Debugging tips:

* nginx logs are at `/var/log/nginx`, php log at `/var/log/php5-fpm.log`
