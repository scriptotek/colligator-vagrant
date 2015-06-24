
## Colligator Vagrant box

### Setup

First create a new GitHub Personal Access Token
at https://github.com/settings/tokens/new
(access scope: public_repo), and store it a
plain text file `github_token` in the `provision` directory
(needed to avoid `composer` running into the GitHub API rate limit).
Then

    git clone git@github.com:scriptotek/colligator-frontend.git
    git clone git@github.com:scriptotek/colligator-backend.git
    vagrant up

should bring up a dev server on http://172.28.128.9/

Use `vagrant ssh` to SSH into the box. You'll find

* `colligator-frontend` mounted at `/var/www/frontend`
* `colligator-backend` mounted at `/var/www/backend`

Nginx setup:

* `/api` → `/var/www/backend/public`
* `/` → `/var/www/frontend`

Open ports:

* 80 http
* 3306 mysql

Debugging tips:

* nginx logs are at `/var/log/nginx`, php log at `/var/log/php5-fpm.log`
