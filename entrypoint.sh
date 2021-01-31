#!/usr/bin/env bash
set -xeo pipefail

if [ ! -z $FORCE_HTTPS ]
then
	sed -i 's#</VirtualHost#SetEnv HTTPS on\n</VirtualHost#' /etc/apache2/sites-enabled/000-default.conf
fi

cp -r storage.skel/* storage/

php /wait-for-db.php

if [[ ! -e storage/.docker.init ]]
then
	echo "Fresh installation, initializing database..."
	gosu www-data php artisan key:generate
	gosu www-data php artisan migrate:fresh --force
	gosu www-data php artisan passport:keys
	echo done > storage/.docker.init
fi

gosu www-data php artisan storage:link
gosu www-data php artisan horizon:publish
gosu www-data php artisan cache:clear
gosu www-data php artisan route:cache
gosu www-data php artisan view:cache
gosu www-data php artisan config:cache

echo "++++ Check for needed migrations... ++++"
# check for migrations
gosu www-data php artisan migrate:status | grep No && migrations=yes || migrations=no
if [ $migrations = "yes" ];
then
	gosu www-data php artisan migrate --force
fi

# create instance actor
gosu www-data php artisan instance:actor

echo "++++ Start apache... ++++"
source /etc/apache2/envvars
/usr/local/sbin/dumb-init apache2 -DFOREGROUND
