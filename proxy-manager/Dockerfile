ARG BUILD_FROM=hassioaddons/base:4.0.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
# hadolint ignore=DL3003
RUN \
    apk add --no-cache --virtual .build-dependencies \
        build-base=0.5-r1 \
        git=2.22.0-r0 \
        npm=10.16.0-r0 \
        patch=2.7.6-r4 \
        python2=2.7.16-r1 \
        yarn=1.12.3-r0 \
    \
    && apk add --no-cache \
        apache2-utils=2.4.39-r0 \
        certbot=0.30.2-r2 \
        mariadb-client=10.3.15-r0 \
        mariadb=10.3.15-r0 \
        nginx-mod-stream=1.14.2-r1 \
        nginx=1.14.2-r1 \
        nodejs=10.14.2-r0 \
        openssl=1.1.1b-r1 \
        dnsmasq=2.80-r3 \
        libcap=2.26-r0 \
    \
    && yarn global add modclean \
    \
    && curl -J -L -o /tmp/nginxproxymanager.tar.gz \
        "https://github.com/jc21/nginx-proxy-manager/archive/2.0.13.tar.gz" \
    && mkdir /app \
    && tar zxvf \
        /tmp/nginxproxymanager.tar.gz \
        --strip 1 -C /app \
    \
    && sed -i "s#canShow('streams')#false#g" \
        /app/src/frontend/js/app/ui/menu/main.ejs \
    && sed -i "s#canShow('streams')#false#g" \
        /app/src/frontend/js/app/dashboard/main.ejs \
    && sed -i "s#, 'streams',#,#g" \
        /app/src/frontend/js/app/user/permissions.ejs \
    \
    && cd /app \
    && yarn install \
    && npm run-script build \
    && rm -rf node_modules \
    && yarn install --production \
    \
    && mkdir -p /opt/nginx-proxy-manager/src \
    && cp -r /app/dist /opt/nginx-proxy-manager/ \
    && cp -r /app/knexfile.js /opt/nginx-proxy-manager/ \
    && cp -r /app/node_modules /opt/nginx-proxy-manager/ \
    && cp -r /app/package.json /opt/nginx-proxy-manager/ \
    && cp -r /app/src/backend /opt/nginx-proxy-manager/src/ \
    \
    && rm -f -r /etc/nginx \
    && cp -r /app/rootfs/etc/nginx /etc/nginx \
    \
    && mkdir -p \
        /run/mysqld \
        /run/nginx \
    \
    && modclean \
        --path /opt/nginx-proxy-manager \
        --no-progress \
        --keep-empty \
        --run \
    \
    && yarn global remove modclean \
    && yarn cache clean \
    \
    && apk del --purge .build-dependencies \
    \
    && rm -f -r \
        /app \
        /etc/init.d/nginx \
        /etc/logrotate.d/nginx \
        /opt/nginx-proxy-manager/node_modules/bcrypt/build \
        /root/.node-gyp \
        /tmp/.[!.]* \
        /tmp/* \
        /usr/lib/node_modules \
        /usr/local/share/.cache \
        /var/lib/mysql \
        /var/lib/nginx \
        /var/log/nginx \
        /var/tmp/nginx \
        /var/www

# Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Nginx Proxy Manager" \
    io.hass.description="Manage Nginx proxy hosts with a simple, powerful interface." \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.label-schema.description="Manage Nginx proxy hosts with a simple, powerful interface" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="Nginx Proxy Manager" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://community.home-assistant.io/t/community-hass-io-add-on-nginx-proxy-manager/111830?u=frenck" \
    org.label-schema.usage="https://github.com/hassio-addons/addon-nginx-proxy-manager/tree/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/hassio-addons/addon-nginx-proxy-manager" \
    org.label-schema.vendor="Community Hass.io Add-ons"
