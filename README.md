# About

This Docker container with PHP 5.3 on Ubuntu 12.04 comes configured with tools for Drupal 6 & 7 projects.

When developing, this project should be used in conjunction with [docker-drupal-php53-dev](https://github.com/andrewholgate/docker-drupal-php53-dev)

# Included Tools

- Apache 2.2.x configured for HTTP & HTTPS and with minimal modules installed.
- PHP 5.3.x with production settings
- MySQL client
- [Alternative PHP Cache](http://pecl.php.net/package/APC) (APC)
- [git](http://git-scm.com/) (latest version)
- [Composer](https://getcomposer.org/)
- [Drush 7](https://github.com/drush-ops/drush)
- [NodeJS](https://nodejs.org/) - Javascript runtime.
- [Linux troubleshooting tools](http://www.linuxjournal.com/magazine/hack-and-linux-troubleshooting-part-i-high-load)
- Syslogging and common log directory
- Guest user (`ubuntu`)

# Installation

## Create Presistant Database data-only container

```bash
# Build database image based off MySQL 5.5
sudo docker run -d --name mysql-drupal-php53 mysql:5.5 --entrypoint /bin/echo MySQL data-only container for Drupal MySQL
```

## Build Drupal Base Image

```bash
# Clone Drupal docker repository
git clone https://github.com/andrewholgate/docker-drupal-php53.git
cd docker-drupal-php53

# Build docker image
sudo docker build --rm=true --tag="drupal-php53" . | tee ./build.log
```

## Build Project using Docker Compose

```bash
# Customise docker-compose.yml configurations for environment.
cp docker-compose.yml.dist docker-compose.yml
vim docker-compose.yml

# Launch docker containers using Docker Compose.
sudo docker-compose build
sudo docker-compose up -d
```

## Host Access

From the host server, add the web container IP address to the hosts file.

```bash
# Add IP address to hosts file.
sudo bash -c "echo $(sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
dockerdrupalphp53_drupalphp53web_1) \
drupal-php53.example.com \
>> /etc/hosts"
```

## Logging into Web Front-end

```bash
# Using the container name of the web frontend.
sudo docker exec -it dockerdrupalphp53_drupalphp53web_1 su - ubuntu
```
