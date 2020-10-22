ARG BUILD_FROM=hassioaddons/base:8.0.4
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy Python requirements file
COPY requirements.txt /tmp/

# Setup base
# hadolint ignore=DL3003
RUN \
    apk add --no-cache --virtual .build-dependencies \
        build-base=0.5-r2 \
        git=2.26.2-r0 \
        libffi-dev=3.3-r2 \
        npm=12.18.4-r0 \
        openssl-dev=1.1.1g-r0 \
        patch=2.7.6-r6 \
        python3-dev=3.8.5-r0 \
        yarn=1.22.4-r0 \
    \
    && apk add --no-cache \
        apache2-utils=2.4.46-r0 \
        certbot=1.4.0-r0 \
        libcap=2.27-r0 \
        mariadb-client=10.4.15-r0 \
        mariadb=10.4.15-r0 \
        nginx-mod-stream=1.18.0-r0 \
        nginx=1.18.0-r0 \
        nodejs=12.18.4-r0 \
        openssl=1.1.1g-r0 \
        py3-pip=20.1.1-r0 \
        python2=2.7.18-r0 \
        python3=3.8.5-r0 \
    \
    && pip3 install --no-cache-dir -r /tmp/requirements.txt \
    \
    && yarn global add modclean \
    \
    && curl -J -L -o /tmp/nginxproxymanager.tar.gz \
        "https://github.com/jc21/nginx-proxy-manager/archive/v2.6.1.tar.gz" \
    && mkdir /app \
    && tar zxvf \
        /tmp/nginxproxymanager.tar.gz \
        --strip 1 -C /app \
    \
    && sed -i "s#canShow('streams')#false#g" \
        /app/frontend/js/app/ui/menu/main.ejs \
    && sed -i "s#canShow('streams')#false#g" \
        /app/frontend/js/app/dashboard/main.ejs \
    && sed -i "s#, 'streams',#,#g" \
        /app/frontend/js/app/user/permissions.ejs \
    \
    && cd /app/frontend \
    && yarn install \
    && yarn build \
    && rm -rf node_modules \
    \
    && mkdir -p /opt/nginx-proxy-manager/frontend \
    && cp -r /app/frontend/dist/. /opt/nginx-proxy-manager/frontend/ \
    \
    && cd /app/backend \
    && yarn install \
    && rm -rf node_modules \
    && cp -r /app/backend/. /opt/nginx-proxy-manager/ \
    \
    && cd /opt/nginx-proxy-manager \
    && yarn install \
    && rm -rf /etc/services.d/frontend \
    && rm -rf /opt/nginx-proxy-manager/config \
    \
    && rm -f -r /etc/nginx \
    && cp -r /app/docker/rootfs/etc/nginx /etc/nginx \
    && rm -f /etc/nginx/conf.d/dev.conf \
    \
    && sed -i "s#root /app/frontend;#root /opt/nginx-proxy-manager/frontend;#" \
        /etc/nginx/conf.d/production.conf \
    && sed -i "s#table.string('id').notNull().primary();#table.string('id', 32).notNull().primary();#" \
        /opt/nginx-proxy-manager/migrations/20190227065017_settings.js \
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
    io.hass.description="Manage Nginx proxy hosts with a simple, powerful interface" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="Nginx Proxy Manager" \
    org.opencontainers.image.description="Manage Nginx proxy hosts with a simple, powerful interface" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/hassio-addons/addon-nginx-proxy-manager" \
    org.opencontainers.image.documentation="https://github.com/hassio-addons/addon-nginx-proxy-manager/blob/master/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
