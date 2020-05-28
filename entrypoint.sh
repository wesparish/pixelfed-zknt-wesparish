#!/usr/bin/env bash

cd /var/www
cp -r storage.skel/* storage/

php artisan storage:link
php artisan horizon:assets
php artisan route:cache
php artisan view:cache
php artisan config:cache

source /etc/apache2/envvars
/usr/local/sbin/dumb-init apache2 -DFOREGROUND
