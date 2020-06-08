#!/usr/bin/env bash
set -xeo pipefail

cp -r storage.skel/* storage/

php /wait-for-db.php

if [[ ! -e storage/.docker.init ]]
then
	echo "Fresh installation, initializing database..."
	php artisan key:generate
	php artisan migrate:fresh --force
	php artisan passport:install
	chown www-data:www-data storage/oauth*key
	echo done > storage/.docker.init
fi

php artisan storage:link
php artisan horizon:assets
php artisan route:cache
php artisan view:cache
php artisan config:cache

echo "++++ Check for needed migrations... ++++"
# check for migrations
php artisan migrate:status | grep No && migrations=yes || migrations=no
if [ $migrations = "yes" ];
then
	php artisan migrate --force
fi

echo "++++ Start apache... ++++"
source /etc/apache2/envvars
/usr/local/sbin/dumb-init apache2 -DFOREGROUND
