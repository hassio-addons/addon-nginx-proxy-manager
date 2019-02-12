#!/usr/bin/with-contenv bash
# ==============================================================================
# Community Hass.io Add-ons: Nginx Proxy Manager
# This file generates a dummy SSL certificate
# ==============================================================================
# shellcheck disable=SC1091
source /usr/lib/hassio-addons/base.sh

if ! hass.directory_exists "/data/nginx"; then
    mkdir -p \
        /data/nginx/dead_host \
        /data/nginx/proxy_host \
        /data/nginx/redirection_host \
        /data/nginx/stream \
        /data/nginx/temp
fi

if ! hass.directory_exists "/data/logs/letsencrypt"; then
    mkdir -p /data/logs/letsencrypt
fi

if ! hass.directory_exists "/data/letsencrypt-acme-challenge"; then
    mkdir /data/letsencrypt-acme-challenge
    mkdir /data/letsencrypt-workdir
fi

if ! hass.directory_exists "/data/mysql"; then
    mkdir /data/mysql
    chown mysql:mysql /data/mysql
fi

if ! hass.directory_exists "/data/manager"; then
    mkdir /data/manager
    cp /defaults/production.json /data/manager/production.json
fi

if ! hass.directory_exists "/ssl/nginxproxymanager"; then
    mkdir -p \
        /ssl/nginxproxymanager
fi

# TODO: Fix the lets encrypt folders
if ! hass.file_exists [ -f ~/.config/letsencrypt/cli.ini ]; then
    mkdir -p ~/.config/letsencrypt || true
    cp /defaults/cli.ini ~/.config/letsencrypt/cli.ini
fi

# Creates basic temporary files directory structure
# Needed for caching
mkdir -p \
    /tmp/nginx \
    /tmp/nginx/proxy \
    /tmp/nginx/body \
    /tmp/nginx/cache/public \
    /tmp/nginx/cache/private

ln -s /tmp/nginx /var/tmp/nginx
ln -s /data/manager /opt/nginx-proxy-manager/config

ln -sf /proc/1/fd/1 /data/logs/default.log
ln -sf /proc/1/fd/1 /data/logs/manager.log
ln -sf /proc/1/fd/1 /data/logs/letsencrypt-requests.log

ln -sf /ssl/nginxproxymanager /etc/letencrypt

# NGinx needs this file to be able to start.
# It will not continously log into it.
mkdir -p /var/lib/nginx/logs
touch /var/lib/nginx/logs/error.log
chmod 777 /var/lib/nginx/logs/error.log
