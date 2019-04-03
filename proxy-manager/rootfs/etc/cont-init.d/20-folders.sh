#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community Hass.io Add-ons: Nginx Proxy Manager
# This file generates a dummy SSL certificate
# ==============================================================================

if ! bashio::fs.directory_exists "/data/nginx"; then
    mkdir -p \
        /data/nginx/dead_host \
        /data/nginx/proxy_host \
        /data/nginx/redirection_host \
        /data/nginx/stream \
        /data/nginx/temp
fi

if ! bashio::fs.directory_exists "/data/logs/letsencrypt"; then
    mkdir -p /data/logs/letsencrypt
fi

if ! bashio::fs.directory_exists "/data/letsencrypt-acme-challenge"; then
    mkdir /data/letsencrypt-acme-challenge
    mkdir /data/letsencrypt-workdir
fi

if ! bashio::fs.directory_exists "/data/mysql"; then
    mkdir /data/mysql
    chown mysql:mysql /data/mysql
fi

if ! bashio::fs.directory_exists "/data/manager"; then
    mkdir /data/manager
    cp /defaults/production.json /data/manager/production.json
fi

if ! bashio::fs.directory_exists "/ssl/nginxproxymanager"; then
    mkdir -p \
        /ssl/nginxproxymanager
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

ln -sf /ssl/nginxproxymanager /etc/letsencrypt

# NGinx needs this file to be able to start.
# It will not continously log into it.
mkdir -p /var/lib/nginx/logs
touch /var/lib/nginx/logs/error.log
chmod 777 /var/lib/nginx/logs/error.log
