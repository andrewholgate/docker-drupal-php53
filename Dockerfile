FROM ubuntu:12.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 curl mysql-client supervisor php5 php5-cli php-pear libapache2-mod-php5 php5-gd php5-json php5-mysql openssh-client rsyslog make libpcre3-dev python-software-properties

# Install latest git version.
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git

# Troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
# I/O troubleshooting tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sysstat iotop htop
# Network troubleshooting tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ethtool net-tools iputils-ping nmap dnsutils traceroute
# Other useful tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget nano

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu
RUN ln -s /var/www /home/ubuntu/www
RUN chown -R ubuntu:ubuntu /home/ubuntu

# Install Uploadprogress
RUN pecl install uploadprogress
RUN echo "extension=uploadprogress.so" >> /etc/php5/apache2/conf.d/uploadprogress.ini

# Install APC
RUN printf "\n" | pecl install apc
RUN echo "extension=apc.so" >> /etc/php5/apache2/conf.d/apc.ini

# Install Composer
ENV COMPOSER_HOME /home/ubuntu/.composer
RUN echo "export COMPOSER_HOME=/home/ubuntu/.composer" >> /etc/bash.bashrc
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install drush & Console Table.
USER ubuntu
WORKDIR /home/ubuntu/
RUN composer global require drush/drush:6.*
COPY drushrc.php /home/ubuntu/.drush/drushrc.php
USER root
RUN pear install Console_Table
RUN  ln -s /home/ubuntu/.composer/vendor/drush/drush/drush /usr/local/bin/drush

# Confiure Apache
RUN rm -rf /var/www/*
COPY default /etc/apache2/sites-available/default
COPY default-ssl /etc/apache2/sites-available/default-ssl
RUN a2ensite default default-ssl

# Only enable relevant Apache modules.
RUN printf "*" | a2dismod
RUN a2enmod alias authz_host deflate dir expires headers mime php5 rewrite ssl

# Add Drupal logs to syslog
RUN echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/apache2/php.ini

# Configurations for bash.
RUN echo "export TERM=xterm" >> /etc/bash.bashrc

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Symlink log files.
RUN mkdir -p /var/www/log
RUN ln -s /var/log/apache2/error.log /var/www/log/
RUN ln -s /var/log/apache2/access.log /var/www/log/
RUN ln -s /var/log/drupal.log /var/www/log/
RUN ln -s /var/log/syslog /var/www/log/
RUN echo "alias taillog='tail -f /var/www/log/drupal.log /var/www/log/error.log /var/www/log/syslog'" >> ~/.bashrc

# Set www directory.
RUN ln -s /usr/share/php/apc.php /var/www/
RUN chown -R www-data:www-data /var/www/apc.php

# Set user ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu/

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean

RUN /etc/init.d/apache2 restart

EXPOSE 80 443 22

ENTRYPOINT ["/usr/local/bin/run"]
