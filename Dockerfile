FROM reg.zknt.org/zknt/debian-php as builder

RUN set -xe;\
  apt-install git php-curl php-zip php-bcmath php-intl php-mbstring php-xml &&\
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" &&\
  php -r "if (hash_file('sha384', 'composer-setup.php') === 'e0012edf3e80b6978849f5eff0d4b4e4c79ff1609dd1e613307e16318854d24ae64f26d17af3ef0bf7cfb710ca74755a') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" &&\
  php composer-setup.php &&\
  php -r "unlink('composer-setup.php');" &&\
  php composer.phar global require hirak/prestissimo --no-interaction --no-suggest --prefer-dist &&\
  cd /var && rm -rf www &&\
  git clone https://github.com/pixelfed/pixelfed.git www &&\
  cd www &&\
  curl -L https://github.com/hnrd/pixelfed/commit/6e822b67c50dfb6cc6dc352ce80bf3326b06cca9.patch | git apply &&\
  php /composer.phar install --prefer-dist --no-interaction --no-ansi --optimize-autoloader &&\
  ln -s public html &&\
  chown -R www-data:www-data /var/www &&\
  cp -r storage storage.skel &&\
  rm -rf .git tests contrib CHANGELOG.md LICENSE .circleci .dependabot .github CODE_OF_CONDUCT.md .env.docker CONTRIBUTING.md README.md docker-compose.yml .env.testing phpunit.xml .env.example .gitignore .editorconfig .gitattributes .dockerignore

FROM reg.zknt.org/zknt/debian-php
COPY --from=builder /var/www /var/www
COPY entrypoint.sh /entrypoint.sh
COPY worker-entrypoint.sh /worker-entrypoint.sh
COPY wait-for-db.php /wait-for-db.php
RUN apt-install php-curl php-zip php-bcmath php-intl php-mbstring php-xml optipng pngquant jpegoptim gifsicle ffmpeg php-imagick php-gd php-redis php-mysql &&\
  a2enmod rewrite &&\
  sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
WORKDIR /var/www
VOLUME /var/www/storage /var/www/bootstrap
ENTRYPOINT /entrypoint.sh
