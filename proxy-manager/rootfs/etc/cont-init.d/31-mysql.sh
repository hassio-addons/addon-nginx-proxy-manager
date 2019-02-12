#!/usr/bin/with-contenv bash
# ==============================================================================
# Community Hass.io Add-ons: Nginx Proxy Manager
# This file init the MySQL database
# ==============================================================================
# shellcheck disable=SC1091
source /usr/lib/hassio-addons/base.sh

# Initialize the database data directory.
if ! hass.directory_exists "/data/mysql/mysql"; then

    hass.log.info "Initializing database..."
    s6-setuidgid mysql mysql_install_db --datadir=/data/mysql

    # Start MySQL.
    s6-setuidgid mysql /usr/bin/mysqld --datadir /data/mysql --tmpdir /tmp/ &
    rc="$?"
    pid="$!"
    if [ "$rc" -ne 0 ]; then
        hass.die "Failed to start the database."
    fi

    # Wait until it is ready.
    for _ in $(seq 1 30); do
        if echo 'SELECT 1' | mysql &> /dev/null; then
            break
        fi
        sleep 1
    done

    # Secure the installation.
    printf '\nn\n\n\n\n\n' | /usr/bin/mysql_secure_installation

    # Create the database.
    echo "CREATE DATABASE IF NOT EXISTS \`nginxproxymanager\` ;" | mysql

    # Create the user.
    echo "CREATE USER 'nginxproxymanager'@'%' IDENTIFIED BY 'nginxproxymanager' ;" | mysql
    echo "GRANT ALL ON \`nginxproxymanager\`.* TO 'nginxproxymanager'@'%' ;" | mysql

    # Stop the MySQL server
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        hass.die "Initialization of database failed."
    fi
fi
