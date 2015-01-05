FROM ubuntu:12.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

VOLUME ["/var/www"]

RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl apache2 mysql-client supervisor php5 php5-cli libapache2-mod-php5 php5-gd php5-json php5-mysql openssh-client rsyslog git-core make libpcre3-dev php-pear

ADD default /etc/apache2/sites-available/default
RUN a2enmod rewrite

# Add ubuntu user.
RUN useradd ubuntu -d /home/ubuntu
RUN mkdir -p /home/ubuntu/.ssh
RUN chmod 700 /home/ubuntu/.ssh
RUN chown ubuntu:ubuntu /home/ubuntu/.ssh
RUN export HOME=/home/ubuntu/

# Setup docker group
RUN groupadd docker
RUN gpasswd -a ubuntu docker

RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Add Drupal logs to syslog
RUN echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/apache2/php.ini

# Install APC
RUN printf "\n" | pecl install apc
RUN echo "extension = apc.so" >> /etc/php5/apache2/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

# Install drush
RUN composer global require drush/drush:6.* \
  && ln -s $HOME/.composer/vendor/drush/drush/drush /usr/bin/drush
ADD drushrc_config ~/.drush/drushrc.php
RUN pear install Console_Table

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean

RUN /etc/init.d/apache2 restart

EXPOSE 80 443 22

CMD ["/usr/local/bin/run"]
