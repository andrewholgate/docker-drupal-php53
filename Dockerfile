FROM ubuntu:12.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN apt-get update && \
    apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 curl mysql-client supervisor php5 php5-cli php-pear libapache2-mod-php5 php5-gd php5-json php5-mysql openssh-client rsyslog make libpcre3-dev python-software-properties

# Install latest git version.
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git

# I/O, Network Other useful troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget nano sysstat iotop htop ethtool net-tools iputils-ping nmap dnsutils traceroute

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu && \
    ln -s /var/www /home/ubuntu/www && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Configure Apache
RUN rm -rf /var/www/*
COPY default /etc/apache2/sites-available/default
COPY default-ssl /etc/apache2/sites-available/default-ssl
RUN a2ensite default default-ssl

# Only enable relevant Apache modules.
RUN printf "*" | a2dismod
RUN a2enmod alias authz_host deflate dir expires headers mime php5 rewrite ssl setenvif

# Install Uploadprogress
RUN pecl install uploadprogress && \
    echo "extension=uploadprogress.so" >> /etc/php5/apache2/conf.d/uploadprogress.ini

# Install APC
RUN printf "\n" | pecl install apc && \
    echo "extension=apc.so" >> /etc/php5/apache2/conf.d/apc.ini

# Install Composer
ENV COMPOSER_HOME /home/ubuntu/.composer
RUN echo "export COMPOSER_HOME=/home/ubuntu/.composer" >> /etc/bash.bashrc && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Install drush, Console Table and Phing.
USER ubuntu
WORKDIR /home/ubuntu/
RUN composer global require drush/drush:7.*
COPY drushrc.php /home/ubuntu/.drush/drushrc.php
RUN composer global require phing/phing:~2.0
USER root

# Add tools installed via composer to PATH and Drupal logs to syslog
RUN echo "export PATH=/home/ubuntu/.composer/vendor/bin:$PATH" >> /etc/bash.bashrc && \
    echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Install Node 12.4
RUN cd /opt && \
  wget http://nodejs.org/dist/v0.12.4/node-v0.12.4-linux-x64.tar.gz && \
  tar -xzf node-v0.12.4-linux-x64.tar.gz && \
  mv node-v0.12.4-linux-x64 node && \
  cd /usr/local/bin && \
  ln -s /opt/node/bin/* . && \
  rm -f /opt/node-v0.12.4-linux-x64.tar.gz

# Production PHP settings.
RUN sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/apache2/php.ini && \
    sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/apache2/php.ini

# Configurations for bash.
RUN echo "export TERM=xterm" >> /etc/bash.bashrc

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Symlink log files.
RUN mkdir -p /var/www/log && \
    ln -s /var/log/apache2/error.log /var/www/log/ && \
    ln -s /var/log/apache2/access.log /var/www/log/ && \
    ln -s /var/log/drupal.log /var/www/log/ && \
    ln -s /var/log/syslog /var/www/log/ && \
    echo "alias taillog='tail -f /var/www/log/drupal.log /var/www/log/error.log /var/www/log/syslog'" >> ~/.bashrc

# Set www directory.
RUN ln -s /usr/share/php/apc.php /var/www/ && \
    chown -R www-data:www-data /var/www/apc.php

# Set user ownership
RUN chown -R ubuntu:ubuntu /home/ubuntu/

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean && apt-get autoremove

RUN /etc/init.d/apache2 restart

EXPOSE 80 443 22

ENTRYPOINT ["/usr/local/bin/run"]
