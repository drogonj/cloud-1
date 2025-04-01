FROM wordpress:6.7-php8.2-fpm-alpine

RUN echo 'memory_limit = 256M' > /usr/local/etc/php/conf.d/memory-limit.ini

RUN apk update && apk add --no-cache \
    mariadb-client \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY wp-autoconfig.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-autoconfig.sh

ENTRYPOINT ["wp-autoconfig.sh"]