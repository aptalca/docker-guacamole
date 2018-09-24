#!/bin/bash

CHANGES=false

# Check if properties file exists. If not, copy in the starter database
if [ -f /config/guacamole/guacamole.properties ]; then
  echo "Using existing properties file."
  if [ ! -d /config/guacamole/log ]; then
    echo "Creating Tomcat log directory."
    mkdir -p /config/guacamole/log
  fi
else
  echo "Creating properties from template."
  mkdir -p /config/databases /config/guacamole/extensions /config/guacamole/lib /config/guacamole/log
  cp -R /etc/firstrun/. /config/guacamole
  PW=$(pwgen -1snc 32)
  sed -i -e 's/some_password/'$PW'/g' /config/guacamole/guacamole.properties
  CHANGES=true
fi

# Check if extensions files exists. Copy or upgrade if necessary.
OPTMYSQL=${OPT_MYSQL^^}
if [ "$OPTMYSQL" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*mysql*.jar ]; then
    oldMysqlFiles=( "/config/guacamole/extensions/*mysql*.jar" )
    newMysqlFiles=( "/var/lib/guacamole/extensions/*mysql*.jar" )

    if diff ${oldMysqlFiles[0]} ${newMysqlFiles[0]} >/dev/null ; then
      echo "Using existing MySQL extension."
      if [ ! -d /config/mysql-schema ]; then
        mkdir /config/mysql-schema
        cp -R /root/mysql/* /config/mysql-schema
        CHANGES=true
      fi
    else
      echo "Upgrading MySQL extension."
      rm /config/guacamole/extensions/*mysql*.jar
      cd /config/guacamole/lib
      rm `find /var/lib/guacamole/lib/mysql/ -name "*.jar" -exec basename {} \;`
      cp /var/lib/guacamole/extensions/*mysql*.jar /config/guacamole/extensions
      cp /var/lib/guacamole/lib/mysql/* /config/guacamole/lib
      rm -R /config/mysql-schema/*
      cp -R /root/mysql/* /config/mysql-schema
      CHANGES=true
    fi
  else
    echo "Copying MySQL extension."
    cp /var/lib/guacamole/extensions/*mysql*.jar /config/guacamole/extensions
    cp /var/lib/guacamole/lib/mysql/* /config/guacamole/lib
    mkdir /config/mysql-schema
    cp -R /root/mysql/* /config/mysql-schema
    CHANGES=true
  fi
elif [ "$OPTMYSQL" = "N" ]; then
  if [ -f /config/guacamole/extensions/*mysql*.jar ]; then
    echo "Removing MySQL extension."
    rm /config/guacamole/extensions/*mysql*.jar
    cd /config/guacamole/lib
    rm `find /var/lib/guacamole/lib/mysql/ -name "*.jar" -exec basename {} \;`
    rm -R /config/mysql-schema
  fi
fi

OPTSQLSERVER=${OPT_SQLSERVER^^}
if [ "$OPTSQLSERVER" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*sqlserver*.jar ]; then
    oldSqlServerFiles=( "/config/guacamole/extensions/*sqlserver*.jar" )
    newSqlServerFiles=( "/var/lib/guacamole/extensions/*sqlserver*.jar" )

    if diff ${oldSqlServerFiles[0]} ${newSqlServerFiles[0]} >/dev/null ; then
    	echo "Using existing SQL Server extension."
    else
    	echo "Upgrading SQL Server extension."
    	rm /config/guacamole/extensions/*sqlserver*.jar
      cd /config/guacamole/lib
      rm `find /var/lib/guacamole/lib/sqlserver/ -name "*.jar" -exec basename {} \;`
    	cp /var/lib/guacamole/extensions/*sqlserver*.jar /config/guacamole/extensions
      cp /var/lib/guacamole/lib/sqlserver/* /config/guacamole/lib
      rm -R /config/sqlserver-schema/*
      cp -R /root/sqlserver/* /config/sqlserver-schema
      CHANGES=true
    fi
  else
    echo "Copying SQL Server extension."
    cp /var/lib/guacamole/extensions/*sqlserver*.jar /config/guacamole/extensions
    cp /var/lib/guacamole/lib/sqlserver/* /config/guacamole/lib
    mkdir /config/sqlserver-schema
    cp -R /root/sqlserver/* /config/sqlserver-schema
    CHANGES=true
  fi
elif [ "$OPTSQLSERVER" = "N" ]; then
  if [ -f /config/guacamole/extensions/*sqlserver*.jar ]; then
    echo "Removing SQL Server extension."
    rm /config/guacamole/extensions/*sqlserver*.jar
    cd /config/guacamole/lib
    rm `find /var/lib/guacamole/lib/sqlserver/ -name "*.jar" -exec basename {} \;`
    rm -R /config/sqlserver-schema
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

OPTOPENID=${OPT_OPENID^^}
if [ "$OPTOPENID" = "Y" ]; then
  if [ -f /config/guacamole/extensions/*openid*.jar ]; then
    oldOpenidFiles=( "/config/guacamole/extensions/*openid*.jar" )
    newOpenidFiles=( "/var/lib/guacamole/extensions/*openid*.jar" )

    if diff ${oldOpenidFiles[0]} ${newOpenidFiles[0]} >/dev/null ; then
      echo "Using existing OpenID extension."
    else
      echo "Upgrading OpenID extension."
      rm /config/guacamole/extensions/*openid*.jar
      cp /var/lib/guacamole/extensions/*openid*.jar /config/guacamole/extensions
      CHANGES=true
    fi
  else
    echo "Copying OpenID extension."
    cp /var/lib/guacamole/extensions/*openid*.jar /config/guacamole/extensions
    CHANGES=true
  fi
elif [ "$OPTOPENID" = "N" ]; then
  if [ -f /config/guacamole/extensions/*openid*.jar ]; then
    echo "Removing OpenID extension."
    rm /config/guacamole/extensions/*openid*.jar
  fi
fi

if [ "$CHANGES" = true ]; then
  echo "Updating user permissions."
  chown nobody:users -R /config/guacamole
  chmod 755 -R /config/guacamole
else
  echo "No permissions changes needed."
fi