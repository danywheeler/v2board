FROM php:7.3-apache
MAINTAINER dany
WORKDIR /var/www
COPY . /var/www/
RUN a2enmod rewrite
RUN docker-php-ext-install pdo_mysql
RUN pecl install redis-5.1.1 && docker-php-ext-enable redis
ENV APACHE_DOCUMENT_ROOT /var/www/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN apt-get update -y && apt-get install -y openssl zip unzip git supervisor && apt autoremove -y
RUN echo "[program:apache2]\n\
command=apache2-foreground\n\
[program:v2board]\n\
process_name=%(program_name)s_%(process_num)02d\n\
command=php /var/www/artisan queue:work --queue=send_email\n\
stdout_logfile=/var/www/storage/logs/send-email.log\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/var/www/storage/logs/send-email-error.log\n\
stderr_logfile_maxbytes=0\n\
autostart=true\n\
autorestart=true\n\
startretries=0\n\
numprocs=4" >> /etc/supervisor/conf.d/app.conf
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install
RUN chown -R www-data:www-data /var/www
CMD ["/usr/bin/supervisord","-n","-c","/etc/supervisor/supervisord.conf"]