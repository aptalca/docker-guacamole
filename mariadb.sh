#!/bin/bash

GUAC_VER="0.9.14"
GUAC_UPG_VER="$GUAC_VER"

start_mysql(){
    /usr/bin/mysqld_safe --datadir=/config/databases > /dev/null 2>&1 &
    RET=1
    while [[ RET -ne 0 ]]; do
        mysql -uroot -e "status" > /dev/null 2>&1
        RET=$?
        sleep 1
    done
}

upgrade_database(){
  echo "Upgrading database pre-$GUAC_UPG_VER."
  start_mysql
  echo "$GUAC_VER" > /config/databases/guacamole/version
  mysql -uroot guacamole < /root/mysql/upgrade/upgrade-pre-${GUAC_UPG_VER}.sql
  mysqladmin -u root shutdown
  sleep 3
  chown -R nobody:users /config/databases
  chmod -R 755 /config/databases
  sleep 3
  echo "Upgrade complete."
}

# If databases do not exist, create them
if [ -f /config/databases/guacamole/guacamole_user.ibd ]; then
  echo "Database exists."
  if [ -f /config/databases/guacamole/version ]; then
    OLD_GUAC_VER=$(cat /config/databases/guacamole/version)
    IFS="."
    read -ra OLD_SPLIT <<< "$OLD_GUAC_VER"
    read -ra NEW_SPLIT <<< "$GUAC_VER"
    IFS=" "
    if (( NEW_SPLIT[2] > OLD_SPLIT[2] )); then
      echo "Database being upgraded."
      rm /config/databases/guacamole/version
      upgrade_database
    elif (( OLD_SPLIT[2] > NEW_SPLIT[2] )); then
      echo "Database newer revision, no change needed."
    else
      echo "Database upgrade not needed."
    fi
  else
    GUAC_UPG_VER="0.9.13"
    upgrade_database
  fi
else
  if [ -f /config/guacamole/guacamole.properties ]; then
    echo "Initializing Guacamole database."
    /usr/bin/mysql_install_db --datadir=/config/databases >/dev/null 2>&1
    echo "Database installation complete."
    start_mysql
    echo "Creating Guacamole database."
    mysql -uroot -e "CREATE DATABASE guacamole"
    echo "Creating Guacamole database user."
    PW=$(cat /config/guacamole/guacamole.properties | grep -m 1 "mysql-password:\s" | sed 's/mysql-password:\s//')
    mysql -uroot -e "CREATE USER 'guacamole'@'localhost' IDENTIFIED BY '$PW'"
    echo "Database created. Granting access to 'guacamole' user for localhost."
    mysql -uroot -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole.* TO 'guacamole'@'localhost'"
    mysql -uroot -e "FLUSH PRIVILEGES"
    echo "Creating Guacamole database schema and default admin user."
    mysql -uroot guacamole < /root/mysql/001-create-schema.sql
    mysql -uroot guacamole < /root/mysql/002-create-admin-user.sql
    echo "$GUAC_VER" > /config/databases/guacamole/version
    echo "Shutting down."
    mysqladmin -u root shutdown
    sleep 3
    echo "Setting database file permissions"
    chown -R nobody:users /config/databases
    chmod -R 755 /config/databases
    sleep 3
    echo "Initialization complete."
  else
    echo "Error! Unable to create database. guacamole.properties file does not exist."
    echo "If you see this error message please contact support in the unRAID forums: https://lime-technology.com/forums/topic/54855-support-jasonbean-apache-guacamole/"
  fi
fi

echo "Starting MariaDB..."
/usr/bin/mysqld_safe --skip-syslog --datadir='/config/databases'
