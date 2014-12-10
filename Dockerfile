FROM ubuntu:12.04
MAINTAINER Andrew Holgate <andrewholgate@yahoo.com>

VOLUME ["/var/www"]

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y nano htop curl apache2 supervisor php5 php5-cli libapache2-mod-php5 php5-gd php5-json php5-ldap php5-mysql openssh-client
RUN mkdir -p /var/log/supervisor

RUN useradd ubuntu -d /home/ubuntu
RUN mkdir -p /home/ubuntu/.ssh
RUN chmod 700 /home/ubuntu/.ssh
RUN chown ubuntu:ubuntu /home/ubuntu/.ssh

ADD default /etc/apache2/sites-available/default
RUN a2enmod rewrite
RUN sed -ri 's/^display_errors\s*=\s*Off/display_errors = On/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^display_errors\s*=\s*Off/display_errors = On/g' /etc/php5/cli/php.ini
RUN sed -ri 's/^error_reporting\s*=.*$/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE/g' /etc/php5/apache2/php.ini
RUN sed -ri 's/^error_reporting\s*=.*$/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE/g' /etc/php5/cli/php.ini

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean

# Install Compser
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

# Install drush
RUN composer global require drush/drush:6.* \
  && ln -s $HOME/.composer/vendor/drush/drush/drush /usr/bin/drush
ADD drushrc_config ~/.drush/drushrc.php

EXPOSE 80

CMD ["/usr/local/bin/run"]
