#!/bin/sh -e
/cleanup.sh &
php-fpm7 -D
php7 /docker_config.php
chown lighttpd /var/log/lighttpd
lighttpd -D -f /etc/lighttpd/lighttpd.conf
