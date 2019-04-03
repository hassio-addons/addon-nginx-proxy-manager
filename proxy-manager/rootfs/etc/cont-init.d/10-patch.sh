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
    /etc/nginx/nginx.conf \
