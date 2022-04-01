FROM reg.zknt.org/zknt/debian-php:7.4 as builder

ARG DATE

ENV PHPVER=7.4
ENV IP_PATCH=2722da0c4749b726bfb87ac56ba055940c2d2fc7

RUN set -xe;\
  apt-install git unzip php${PHPVER}-curl php${PHPVER}-zip php${PHPVER}-bcmath php${PHPVER}-intl php${PHPVER}-mbstring php${PHPVER}-xml composer &&\
  cd /var && rm -rf www &&\
  git clone https://github.com/pixelfed/pixelfed.git www &&\
  cd www &&\
  curl -L https://github.com/hnrd/pixelfed/commit/${IP_PATCH}.patch | git apply &&\
  composer require beyondcode/laravel-self-diagnosis &&\
  composer install --prefer-dist --no-interaction --no-ansi --no-dev --optimize-autoloader &&\
  ln -s public html &&\
  chown -R www-data:www-data /var/www &&\
  cp -r storage storage.skel &&\
  rm -rf .git tests contrib CHANGELOG.md LICENSE .circleci .dependabot .github CODE_OF_CONDUCT.md .env.docker CONTRIBUTING.md README.md docker-compose.yml .env.testing phpunit.xml .env.example .gitignore .editorconfig .gitattributes .dockerignore

FROM reg.zknt.org/zknt/debian-php:7.4
ENV PHPVER=7.4
COPY --from=builder /var/www /var/www
COPY entrypoint.sh /entrypoint.sh
COPY worker-entrypoint.sh /worker-entrypoint.sh
COPY wait-for-db.php /wait-for-db.php
RUN apt-install php${PHPVER}-curl php${PHPVER}-zip php${PHPVER}-bcmath php${PHPVER}-intl php${PHPVER}-mbstring php${PHPVER}-xml optipng pngquant jpegoptim gifsicle ffmpeg php${PHPVER}-imagick php${PHPVER}-gd php${PHPVER}-redis php${PHPVER}-mysql php${PHPVER}-pgsql &&\
  a2enmod rewrite &&\
  sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf &&\
  sed -i 's/^post_max_size.*/post_max_size = 100M/g' /etc/php/${PHPVER}/apache2/php.ini &&\
  sed -i 's/^upload_max_filesize.*/upload_max_filesize = 100M/g' /etc/php/${PHPVER}/apache2/php.ini
WORKDIR /var/www
VOLUME /var/www/storage /var/www/bootstrap
ENTRYPOINT /entrypoint.sh

LABEL build.date=$DATE
