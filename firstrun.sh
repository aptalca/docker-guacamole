#!/bin/bash

# Check if properties file exists. If not, copy in the starter database
if [ -f /config/guacamole/guacamole.properties ]; then
  echo "Using existing properties file."
else
  echo "Creating properties from template."
  mkdir -p /config/databases /config/guacamole/extensions
  cp -R /etc/firstrun/. /config/guacamole
  PW=$(pwgen -1snc 32)
  sed -i -e 's/some_password/'$PW'/g' /config/guacamole/guacamole.properties
fi

# Check if LDAP extensions file exists. Copy or upgrade if necessary.
if [ -e /config/guacamole/extensions/*ldap*.jar ]; then
  oldAuthFiles=( "/config/guacamole/extensions/*ldap*.jar" )
  newAuthFiles=( "/var/lib/guacamole/extensions/*ldap*.jar" )
  if diff ${oldAuthFiles[0]} ${newAuthFiles[0]} >/dev/null ; then
  	echo "Using existing LDAP extension."
  else
  	echo "Upgrading LDAP extension."
  	rm /config/guacamole/extensions/*ldap*.jar
  	rm -R /config/ldap-schema
  	cp /var/lib/guacamole/extensions/*ldap*.jar /config/guacamole/extensions
  	cp -R /var/lib/guacamole/ldap-schema /config
  fi
else
  echo "Copying LDAP extension."
  cp /var/lib/guacamole/extensions/*ldap*.jar /config/guacamole/extensions
  cp -R /var/lib/guacamole/ldap-schema /config
fi

ln -s /config/guacamole /usr/share/tomcat7/.guacamole
chown nobody:users -R /config/
chmod 755 -R /config/
