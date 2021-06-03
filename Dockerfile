FROM php:7.3-fpm-alpine
MAINTAINER "Jérôme Jutteau <jerome@jutteau.fr>"

# lighttpd user
ARG USER_ID=101
# www-data group
ARG GROUP_ID=82

# install base
RUN apk update && \
    ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime  && \
    echo "UTC" > /etc/timezone


# install jirafeau
RUN mkdir /www
WORKDIR /www
COPY .git .git
RUN apk add git && \
    git checkout guilhem/oauth_support && git reset --hard && rm -rf docker install.php .git .gitignore .gitlab-ci.yml CONTRIBUTING.md Dockerfile README.md && \
    apk del git && \
    touch /www/lib/config.local.php && \
    chown -R $USER_ID.$GROUP_ID /www && \
    chmod o=,ug=rwX -R /www

COPY docker/cleanup.sh /cleanup.sh
COPY docker/run.sh /run.sh
RUN chmod o=,ug=rx /cleanup.sh /run.sh
COPY docker/docker_config.php /docker_config.php

# install lighttpd
RUN apk add lighttpd php7-mcrypt && \
    echo "extension=/usr/lib/php7/modules/mcrypt.so" > /usr/local/etc/php/conf.d/mcrypt.ini && \
    chown -R $USER_ID:$GROUP_ID /var/log/lighttpd && \
    mkdir -p /usr/local/etc/php && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    php composer.phar install
 
COPY docker/php.ini /usr/local/etc/php/php.ini
COPY docker/lighttpd.conf /etc/lighttpd/lighttpd.conf

# cleanup
RUN rm -rf /var/cache/apk/*

CMD /run.sh
EXPOSE 80
