#!/bin/bash
set -e

exec supervisord -n -c /etc/supervisor/conf.d/supervisord.conf

exec "$@"
