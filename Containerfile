FROM docker.io/php:8.1-apache-bullseye as builder

ARG VERSION=dev

ARG DATE

ENV IP_PATCH=14cca91255bca69dec195112ce2fbd110e2406ca
ENV DISCOVERY_PATCH=f4a01bc97efeb259fd0c6e2016949c90675cc555
ENV GITHUB_PATCH=06bcf80133f6c212f1674d280974c669b4524283
ENV BEAGLE_PATCH=f45a489d5e45de21d648437880ef525a2e957b7b
ENV USERNAME_PATCH=737319bff8697263df19b9b4c0a2ee7cc8055476

RUN set -xe;\
  apt-get update &&\
  apt-get install --no-install-recommends -y git locales libcurl4-openssl-dev libzip-dev libicu-dev libxml2-dev libjpeg62-turbo-dev libpng-dev libmagickwand-dev libpq-dev libxpm-dev libwebp-dev &&\
  apt-get clean all &&\
  rm -rf /var/lib/apt/lists/*

RUN set -xe;\
  docker-php-ext-configure mbstring --disable-mbregex &&\
  docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm &&\
  docker-php-ext-install -j$(nproc) curl zip bcmath intl mbstring xml pcntl gd mysqli pdo_mysql pdo_pgsql opcache &&\
  pecl install imagick &&\
  pecl install redis &&\
  docker-php-ext-enable imagick redis
RUN set -xe;\
  curl https://raw.githubusercontent.com/composer/getcomposer.org/0a51b6fe383f7f61cf1d250c742ec655aa044c94/web/installer | php -- --quiet --2.2 &&\
  mv composer.phar /usr/local/bin/composer

RUN set -xe;\
  cd /var && rm -rf www &&\
  git clone https://github.com/pixelfed/pixelfed.git www &&\
  cd www &&\
  git checkout $VERSION &&\
  curl -L https://git.zknt.org/chris/pixelfed/commit/${IP_PATCH}.patch | git apply &&\
  curl -L https://git.zknt.org/chris/pixelfed/commit/${DISCOVERY_PATCH}.patch | git apply &&\
  curl -L https://git.zknt.org/chris/pixelfed/commit/${GITHUB_PATCH}.patch | git apply &&\
  curl -L https://git.zknt.org/chris/pixelfed/commit/${BEAGLE_PATCH}.patch | git apply &&\
  curl -L https://git.zknt.org/chris/pixelfed/commit/${USERNAME_PATCH}.patch | git apply &&\
  composer install --prefer-dist --no-interaction --no-ansi --no-dev --optimize-autoloader &&\
  ln -s public html &&\
  chown -R www-data:www-data /var/www &&\
  cp -r storage storage.skel &&\
  rm -rf .git tests contrib CHANGELOG.md LICENSE .circleci .dependabot .github CODE_OF_CONDUCT.md .env.docker CONTRIBUTING.md README.md docker-compose.yml .env.testing phpunit.xml .env.example .gitignore .editorconfig .gitattributes .dockerignore

FROM docker.io/php:8.1-apache-bullseye
ARG DATE
ARG VERSION=dev

COPY --from=builder /var/www /var/www
COPY entrypoint.sh /entrypoint.sh
COPY worker-entrypoint.sh /worker-entrypoint.sh
COPY websockets-entrypoint.sh /websockets-entrypoint.sh
COPY wait-for-db.php /wait-for-db.php
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20210902 /usr/local/lib/php/extensions/no-debug-non-zts-20210902
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

RUN set -xe;\
  apt-get update &&\
  apt-get install --no-install-recommends -y libzip4 libpq5 libmagickwand-6.q16-6 libxpm4 libwebp6 &&\
  apt-get install --no-install-recommends -y optipng pngquant jpegoptim gifsicle ffmpeg locales gosu dumb-init &&\
  apt-get clean all &&\
  rm -rf /var/lib/apt/lists/*

RUN set -xe;\
  a2enmod rewrite &&\
  sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf &&\
  sed -i 's/^post_max_size.*/post_max_size = 100M/g' "$PHP_INI_DIR"/php.ini* &&\
  sed -i 's/^upload_max_filesize.*/upload_max_filesize = 100M/g' "$PHP_INI_DIR"/php.ini* &&\
  mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
WORKDIR /var/www
VOLUME /var/www/storage /var/www/bootstrap
ENTRYPOINT /entrypoint.sh

LABEL build.date=$DATE version.pixelfed=$VERSION
