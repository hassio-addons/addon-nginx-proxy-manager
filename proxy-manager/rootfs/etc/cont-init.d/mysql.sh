#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: Nginx Proxy Manager
# This file init the MySQL database
# ==============================================================================
declare host
declare password
declare port
declare username

# return on error
set -e

# Check if MySQL service is available
if bashio::services.available "mysql"; then
	host=$(bashio::services "mysql" "host")
	password=$(bashio::services "mysql" "password")
	port=$(bashio::services "mysql" "port")
	username=$(bashio::services "mysql" "username")

	# Check if nginxproxymanager databse exists
	if mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}" -e "USE nginxproxymanager"; then 
		bashio::log.info "mysql database nginxproxymanager exists, trying to convert"; 
		# Option 1: https://pypi.org/project/mysql-to-sqlite3/
		# mysql2sqlite -h "${host}" -P "${port}" -u "${username}" --mysql-password "${password}" -f $DB_SQLITE_FILE -V -q		
		# Option 2: https://github.com/dumblob/mysql2sqlite
		bashio::log.info "Downloading mysql2sqlite..."
		wget https://raw.githubusercontent.com/dumblob/mysql2sqlite/master/mysql2sqlite -o /tmp/mysql2sqlite
		chmod +x /tmp/mysql2sqlite
		bashio::log.info "Dumping mysql database..."
		mysqldump --skip-extended-insert --compact -h "${host}" -P "${port}" -u "${username}" -p"${password}" nginxproxymanager > /tmp/dump_mysql.sql
		bashio::log.info "Converting dump and creating sqlite database..."		
		/tmp/mysql2sqlite /tmp/dump_mysql.sql | sqlite3 $DB_SQLITE_FILE
		
		# Create a backup database in mysql for any case (rename would be easier but seems not to be possible)
		bashio::log.info "Creating nginxproxymanager.backup database for any case..."
		mysqladmin -h "${host}" -P "${port}" -u username -p"password" create nginxproxymanager.backup
		mysql -h "${host}" -P "${port}" -u username -p"password" nginxproxymanager.backup < /tmp/dump_mysql.sql
		bashio::log.info "If the sqlite database works as expected, please delete nginxproxymanager.backup manually or stop the mysql addon"
		
		# Drop database if it exists and conversion was successful		
		bashio::log.info "Dropping mysql database nginxproxymanager"
		echo "DROP DATABASE IF EXISTS nginxproxymanager;" \
		| mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"
	fi
fi

#Drop database based on config flag
if bashio::config.true 'reset_database'; then
	bashio::log.warning 'Recreating database'
	# remove sqlite file
	[ -f $DB_SQLITE_FILE ] && rm -f $DB_SQLITE_FILE
	#Remove reset_database option
	bashio::addon.option 'reset_database'
fi
