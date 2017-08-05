#!/bin/bash

# Check if properties file exists. If not, copy in the starter database
if [ -f /config/guacamole/guacamole.properties ]; then
  echo "Using existing properties file."
else
  echo "Creating properties from template."
  mkdir -p /config/databases /config/guacamole/extensions /config/guacamole/lib
  cp -R /etc/firstrun/. /config/guacamole
  PW=$(pwgen -1snc 32)
  sed -i -e 's/some_password/'$PW'/g' /config/guacamole/guacamole.properties
fi

CHANGES=false

# Check if extensions files exists. Copy or upgrade if necessary.
OPTMYSQL=${OPT_MYSQL^^}
if [ "$OPTMYSQL" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*mysql*.jar ]; then
    oldDuoFiles=( "/config/guacamole/extensions/*mysql*.jar" )
    newDuoFiles=( "/var/lib/guacamole/extensions/*mysql*.jar" )

    if diff ${oldDuoFiles[0]} ${newDuoFiles[0]} >/dev/null ; then
      echo "Using existing MySQL extension."
    else
      echo "Upgrading MySQL extension."
      rm /config/guacamole/extensions/*mysql*.jar
      rm /config/guacamole/lib/*
      cp /var/lib/guacamole/extensions/*mysql*.jar /config/guacamole/extensions
      cp /var/lib/guacamole/lib/* /config/guacamole/lib
      CHANGES=true
    fi
  else
    echo "Copying MySQL extension."
    cp /var/lib/guacamole/extensions/*mysql*.jar /config/guacamole/extensions
    cp /var/lib/guacamole/lib/* /config/guacamole/lib
    CHANGES=true
  fi
elif [ "$OPTMYSQL" = "N" ]; then
  if [ -f /config/guacamole/extensions/*mysql*.jar ]; then
    echo "Removing MySQL extension."
    rm /config/guacamole/extensions/*mysql*.jar
    rm /config/guacamole/lib/*
  fi
fi

OPTLDAP=${OPT_LDAP^^}
if [ "$OPTLDAP" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*ldap*.jar ]; then
    oldLDAPFiles=( "/config/guacamole/extensions/*ldap*.jar" )
    newLDAPFiles=( "/var/lib/guacamole/extensions/*ldap*.jar" )

    if diff ${oldLDAPFiles[0]} ${newLDAPFiles[0]} >/dev/null ; then
    	echo "Using existing LDAP extension."
    else
    	echo "Upgrading LDAP extension."
    	rm /config/guacamole/extensions/*ldap*.jar
    	rm -R /config/ldap-schema
    	cp /var/lib/guacamole/extensions/*ldap*.jar /config/guacamole/extensions
    	cp -R /var/lib/guacamole/ldap-schema /config
      CHANGES=true
    fi
  else
    echo "Copying LDAP extension."
    cp /var/lib/guacamole/extensions/*ldap*.jar /config/guacamole/extensions
    cp -R /var/lib/guacamole/ldap-schema /config
    CHANGES=true
  fi
elif [ "$OPTLDAP" = "N" ]; then
  if [ -f /config/guacamole/extensions/*ldap*.jar ]; then
    echo "Removing LDAP extension."
    rm /config/guacamole/extensions/*ldap*.jar
    rm -R /config/ldap-schema
  fi
fi

OPTDUO=${OPT_DUO^^}
if [ "$OPTDUO" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*duo*.jar ]; then
    oldDuoFiles=( "/config/guacamole/extensions/*duo*.jar" )
    newDuoFiles=( "/var/lib/guacamole/extensions/*duo*.jar" )

    if diff ${oldDuoFiles[0]} ${newDuoFiles[0]} >/dev/null ; then
      echo "Using existing Duo extension."
    else
      echo "Upgrading Duo extension."
      rm /config/guacamole/extensions/*duo*.jar
      cp /var/lib/guacamole/extensions/*duo*.jar /config/guacamole/extensions
      CHANGES=true
    fi
  else
    echo "Copying Duo extension."
    cp /var/lib/guacamole/extensions/*duo*.jar /config/guacamole/extensions
    CHANGES=true
  fi
elif [ "$OPTDUO" = "N" ]; then
  if [ -f /config/guacamole/extensions/*duo*.jar ]; then
    echo "Removing Duo extension."
    rm /config/guacamole/extensions/*duo*.jar
  fi
fi

OPTCAS=${OPT_CAS^^}
if [ "$OPTCAS" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*cas*.jar ]; then
    oldCasFiles=( "/config/guacamole/extensions/*cas*.jar" )
    newCasFiles=( "/var/lib/guacamole/extensions/*cas*.jar" )

    if diff ${oldCasFiles[0]} ${newCasFiles[0]} >/dev/null ; then
      echo "Using existing CAS extension."
    else
      echo "Upgrading CAS extension."
      rm /config/guacamole/extensions/*cas*.jar
      cp /var/lib/guacamole/extensions/*cas*.jar /config/guacamole/extensions
      CHANGES=true
    fi
  else
    echo "Copying CAS extension."
    cp /var/lib/guacamole/extensions/*cas*.jar /config/guacamole/extensions
    CHANGES=true
  fi
elif [ "$OPTCAS" = "N" ]; then
  if [ -f /config/guacamole/extensions/*cas*.jar ]; then
    echo "Removing CAS extension."
    rm /config/guacamole/extensions/*cas*.jar
  fi
fi

if [ "$CHANGES" = true ]; then
  echo "Updating user permissions."
  chown nobody:users -R /config/
  chmod 755 -R /config/
else
  echo "No permissions changes needed."
fi