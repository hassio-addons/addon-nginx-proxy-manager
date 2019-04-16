#!/usr/bin/with-contenv bashio
# ==============================================================================
# Community Hass.io Add-ons: Nginx Proxy Manager
# This file applies patches so the add-on becomes compatible
# ==============================================================================
# Redirect log output to the Hass.io add-on log
sed -i 's#/data/logs/error.log#/proc/1/fd/1#g' /etc/nginx/nginx.conf
sed -i 's#/data/logs/default.log#/proc/1/fd/1#g' /etc/nginx/nginx.conf
sed -i 's#/data/logs/dead_host-{{ id }}.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/src/backend/templates/dead_host.conf
sed -i 's#/data/logs/redirection_host-{{ id }}.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/src/backend/templates/redirection_host.conf
sed -i 's#/data/logs/proxy_host-{{ id }}.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/src/backend/templates/proxy_host.conf \

# Store cache in a temporary folder
sed -i 's#/var/lib/nginx/cache/public#/tmp/nginx/cache/public#g' \
    /etc/nginx/nginx.conf
sed -i 's#/var/lib/nginx/cache/private#/tmp/nginx/cache/private#g' \
    /etc/nginx/nginx.conf

# Add Stream module
sed -i 's#daemon off;#daemon off;\nload_module /usr/lib/nginx/modules/ngx_stream_module.so;#g' \
    /etc/nginx/nginx.conf

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

# This file generates a dummy SSL certificate
if [[ ! -f /data/nginx/dummycert.pem ]] || [[ ! -f /data/nginx/dummykey.pem ]]
then
  bashio::log.info "Generating dummy SSL certificate"
  openssl req \
    -new \
    -newkey rsa:2048 \
    -days 3650 \
    -nodes \
    -x509 \
    -subj '/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost' \
    -keyout /data/nginx/dummykey.pem \
    -out /data/nginx/dummycert.pem \
    || bashio::exit.nok "Could not generate dummy certificate"
fi
