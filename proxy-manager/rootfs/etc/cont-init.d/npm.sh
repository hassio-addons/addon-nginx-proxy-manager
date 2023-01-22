#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Nginx Proxy Manager
# This file applies patches so the add-on becomes compatible
# ==============================================================================

# Redirect log output to the add-on log
sed -i 's#/data/logs/fallback_error.log#/proc/1/fd/1#g' /etc/nginx/nginx.conf
sed -i 's#/data/logs/fallback_access.log#/proc/1/fd/1#g' /etc/nginx/nginx.conf
sed -i 's#/data/logs/dead-host-{{ id }}_access.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/dead_host.conf
sed -i 's#/data/logs/dead-host-{{ id }}_error.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/dead_host.conf
sed -i 's#/data/logs/redirection-host-{{ id }}_access.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/redirection_host.conf
sed -i 's#/data/logs/redirection-host-{{ id }}_error.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/redirection_host.conf
sed -i 's#/data/logs/proxy-host-{{ id }}_access.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/proxy_host.conf
sed -i 's#/data/logs/proxy-host-{{ id }}_error.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/proxy_host.conf
sed -i 's#/data/logs/fallback_access.log#/proc/1/fd/1#g' /etc/nginx/conf.d/default.conf
sed -i 's#/data/logs/fallback_error.log#/proc/1/fd/1#g' /etc/nginx/conf.d/default.conf
sed -i 's#/data/logs/fallback_access.log#/proc/1/fd/1#g' /etc/nginx/conf.d/default.conf
sed -i 's#/data/logs/letsencrypt-requests_access.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/letsencrypt-request.conf
sed -i 's#/data/logs/letsencrypt-requests_error.log#/proc/1/fd/1#g' \
    /opt/nginx-proxy-manager/templates/letsencrypt-request.conf

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
fi

if ! bashio::fs.directory_exists "/ssl/nginxproxymanager"; then
    mkdir -p \
        /ssl/nginxproxymanager
fi

if ! bashio::fs.directory_exists "/data/nginx/default_host"; then
    mkdir -p \
        /data/nginx/default_host \
        /data/nginx/default_www
fi

# Creates basic temporary files directory structure
# Needed for caching
mkdir -p \
    /tmp/nginx \
    /tmp/nginx/proxy \
    /tmp/nginx/body \
    /tmp/nginx/cache/public \
    /tmp/nginx/cache/private \
    /var/lib/nginx/

ln -s /tmp/nginx /var/tmp/nginx
ln -s /tmp/nginx /var/lib/nginx/tmp
ln -s /data/manager /opt/nginx-proxy-manager/config

#Tidy unneeded symlinks
if bashio::fs.file_exists "/data/logs/default.log"; then
    unlink /data/logs/default.log
fi

if  bashio::fs.file_exists "/data/logs/manager.log"; then
    unlink /data/logs/manager.log
fi

if bashio::fs.file_exists "/data/logs/letsencrypt-requests.log"; then
    unlink /data/logs/letsencrypt-requests.log
fi

ln -sf /ssl/nginxproxymanager /etc/letsencrypt

# NGinx needs this file to be able to start.
# It will not continously log into it.
mkdir -p /var/lib/nginx/logs
touch /var/lib/nginx/logs/error.log
chmod 777 /var/lib/nginx/logs/error.log

# This file generates a dummy SSL certificate
if ! bashio::fs.directory_exists "/data/nginx/dummycert.pem" && ! bashio::fs.file_exists "/data/nginx/dummykey.pem";
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
