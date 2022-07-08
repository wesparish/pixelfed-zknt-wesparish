#!/usr/bin/env bash
set -xeo pipefail

php /wait-for-db.php

if [[ ! -e storage/.docker.init ]];
then
	echo "Database is not initialized yet, exiting..."
	sleep 5
	exit 1
fi

gosu www-data php artisan migrate:status | grep No && migrations=yes || migrations=no
if [ $migrations = "yes" ];
then
	echo "Database needs migrations, exiting..."
	sleep 5
	exit 1
fi

gosu www-data php artisan websockets:serve
