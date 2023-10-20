#!/usr/bin/env bash
set -xeo pipefail

rsync -a --delete storage.skel/* storage/
rsync -a --delete public.skel/ public/
chown -R www-data:www-data storage/ bootstrap/

php /wait-for-db.php

if [[ ! -e storage/.docker.init ]]
then
	echo "Fresh installation, initializing database..."
	gosu www-data php artisan key:generate
	gosu www-data php artisan migrate:fresh --force
	gosu www-data php artisan passport:keys
	echo completed > storage/.docker.init
fi

gosu www-data php artisan storage:link
gosu www-data php artisan horizon:publish
gosu www-data php artisan config:cache
gosu www-data php artisan cache:clear
gosu www-data php artisan route:cache
gosu www-data php artisan view:cache

rsync --archive --delete public/ /public/

echo "++++ Check for needed migrations... ++++"
# check for migrations
gosu www-data php artisan migrate:status | grep No && migrations=yes || migrations=no
gosu www-data php artisan migrate:status | grep Pending && migrations=yes || migrations=no
if [ "$migrations" = "yes" ];
then
	gosu www-data php artisan migrate --force
fi

# create instance actor
gosu www-data php artisan instance:actor

dumb-init docker-php-entrypoint -F
