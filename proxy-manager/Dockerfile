ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64:9.1.2
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
        git=2.30.1-r0 \
        libffi-dev=3.3-r2 \
        npm=14.15.4-r0 \
        openssl-dev=1.1.1i-r0 \
        patch=2.7.6-r6 \
        python3-dev=3.8.7-r0 \
        yarn=1.22.10-r0 \
    \
    && apk add --no-cache \
        apache2-utils=2.4.46-r3 \
        certbot=1.11.0-r0 \
        libcap=2.46-r0 \
        mariadb-client=10.5.8-r0 \
        mariadb=10.5.8-r0 \
        nginx-mod-stream=1.18.0-r13 \
        nginx=1.18.0-r13 \
        nodejs=14.15.4-r0 \
        openssl=1.1.1i-r0 \
        py3-pip=20.3.4-r0 \
        python2=2.7.18-r1 \
        python3=3.8.7-r0 \
    \
    && pip3 install --no-cache-dir -r /tmp/requirements.txt \
    \
    && yarn global add modclean \
    \
    && curl -J -L -o /tmp/nginxproxymanager.tar.gz \
        "https://github.com/jc21/nginx-proxy-manager/archive/v2.8.0.tar.gz" \
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
    && cp -R /app/global/. /opt/nginx-proxy-manager/global/ \
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
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
