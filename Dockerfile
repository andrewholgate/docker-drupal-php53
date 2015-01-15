FROM ubuntu:12.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl apache2 mysql-client supervisor php5 php5-cli libapache2-mod-php5 php5-gd php5-json php5-mysql openssh-client rsyslog git-core make libpcre3-dev php-pear

# Troubleshooting tools, see: http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load
# I/O troubleshooting tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sysstat iotop htop
# Network troubleshooting tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ethtool net-tools iputils-ping nmap dnsutils traceroute
# Other useful tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget nano

# Install Uploadprogress
RUN pecl install uploadprogress
RUN echo "extension=uploadprogress.so" >> /etc/php5/apache2/conf.d/uploadprogress.ini

# Install APC
RUN printf "\n" | pecl install apc
RUN echo "extension=apc.so" >> /etc/php5/apache2/conf.d/apc.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

# Install drush
RUN composer global require drush/drush:6.* \
  && ln -s $HOME/.composer/vendor/drush/drush/drush /usr/bin/drush
COPY drushrc.php ~/.drush/drushrc.php
RUN pear install Console_Table

# Confiure Apache
COPY default /etc/apache2/sites-available/default
COPY default-ssl /etc/apache2/sites-available/default-ssl
RUN a2enmod rewrite ssl
RUN a2ensite default default-ssl

# Add Drupal logs to syslog
RUN echo "local0.* /var/log/drupal.log" >> /etc/rsyslog.conf

# Production PHP settings.
RUN sed -ri 's/^;error_log\s*=\s*syslog/error_log = syslog/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^short_open_tag\s*=\s*On/short_open_tag = Off/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^memory_limit\s*=\s*128M/memory_limit = 256M/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^expose_php\s*=\s*On/expose_php = Off/g' /etc/php5/apache2/php.ini

# Add ubuntu user.
RUN useradd -ms /bin/bash ubuntu
RUN ln -s /var/www /home/ubuntu/www
RUN echo "export TERM=xterm" >> /home/ubuntu/.profile
RUN chown -R ubuntu:ubuntu /home/ubuntu

# Setup docker group
RUN groupadd docker
RUN gpasswd -a ubuntu docker

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# Clean-up installation.
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean

RUN /etc/init.d/apache2 restart

EXPOSE 80 443 22

ENTRYPOINT ["/usr/local/bin/run"]
