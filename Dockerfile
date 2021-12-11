FROM alpine

# lighttpd user
ARG USER_ID=100
# www-data group
ARG GROUP_ID=82

# install base
RUN apk update && \
    ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime  && \
    echo "UTC" > /etc/timezone && \
    mkdir /www

# install jirafeau
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
RUN apk add lighttpd php7 php7-session php7-cgi php7-fpm php7-mcrypt php7-openssl php7-json php7-phar php7-mbstring && \
    echo "extension=/usr/lib/php7/modules/mcrypt.so" > /etc/php7/conf.d/mcrypt.ini && \
    chown -R $USER_ID:$GROUP_ID /var/log/lighttpd 

RUN \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    php composer.phar install && \
    rm -rf /var/cache/apk/* 
     

COPY docker/php.ini /etc/php7/php.ini
COPY docker/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY docker/mod_fastcgi_fpm.conf /etc/lighttpd/conf.d/mod_fastcgi_fpm.conf
COPY docker/www.conf /etc/php7/php-fpm.d/www.conf

# cleanup

CMD /run.sh
EXPOSE 80
