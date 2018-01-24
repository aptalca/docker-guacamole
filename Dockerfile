### Dockerfile for guacamole
### Includes the mysql authentication module preinstalled

# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.22 as guacd-build

### Version of guacamole to be installed
ENV GUAC_VER 0.9.14
### Version of mysql-connector-java to install
ENV MCJ_VER 5.1.45
### Version of mssql jdbc driver to install
ENV SQL_VER 6.2.2

COPY /deps/build-deps.txt /deps/build-deps.txt

RUN apt-get update && xargs -a /deps/build-deps.txt apt-get install -y --no-install-recommends
WORKDIR /tmp
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" | tar -xz -C /tmp
RUN cd /tmp/guacamole-server-$GUAC_VER && \
    ./configure --with-init-dir=/etc/init.d && \
    make && \
    make install && \
    cd /usr/local/lib && \
    find libguac* -type l -delete

RUN mkdir -p /tmp/guacamole/extensions /tmp/guacamole/lib/mysql /tmp/guacamole/lib/sqlserver /tmp/guacamole/ldap-schema /tmp/root/mysql /tmp/root/sqlserver

### Install LDAP Authentication Module
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-ldap-${GUAC_VER}.tar.gz" | tar -xz
RUN cp -f guacamole-auth-ldap-${GUAC_VER}/guacamole-auth-ldap-${GUAC_VER}.jar /tmp/guacamole/extensions
RUN cp -Rf guacamole-auth-ldap-${GUAC_VER}/schema/* /tmp/guacamole/ldap-schema

### Install Duo Authentication Module
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-duo-${GUAC_VER}.tar.gz" | tar -xz
RUN cp -f guacamole-auth-duo-${GUAC_VER}/guacamole-auth-duo-${GUAC_VER}.jar /tmp/guacamole/extensions

### Install CAS Authentication Module
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-cas-${GUAC_VER}.tar.gz" | tar -xz
RUN cp -f guacamole-auth-cas-${GUAC_VER}/guacamole-auth-cas-${GUAC_VER}.jar /tmp/guacamole/extensions

### Install OpenID Authentication Module
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-openid-${GUAC_VER}.tar.gz" | tar -xz
RUN cp -f guacamole-auth-openid-${GUAC_VER}/guacamole-auth-openid-${GUAC_VER}.jar /tmp/guacamole/extensions

### Install JDBC Authentication Module
RUN wget -O- --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" | tar -xz
RUN cp -f guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar /tmp/guacamole/extensions
RUN cp -Rf guacamole-auth-jdbc-${GUAC_VER}/mysql/schema/* /tmp/root/mysql
RUN cp -f guacamole-auth-jdbc-${GUAC_VER}/sqlserver/guacamole-auth-jdbc-sqlserver-${GUAC_VER}.jar /tmp/guacamole/extensions
RUN cp -Rf guacamole-auth-jdbc-${GUAC_VER}/sqlserver/schema/* /tmp/root/sqlserver

### Install dependancies for mysql authentication module
RUN wget -O- --span-hosts http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MCJ_VER}.tar.gz | tar -xz
RUN cp -f `find ./mysql-connector-java-${MCJ_VER} -type f -name '*.jar'` /tmp/guacamole/lib/mysql

### Install dependancies for SQL Server authentication module
RUN wget --span-hosts "http://github.com/Microsoft/mssql-jdbc/releases/download/v${SQL_VER}/mssql-jdbc-${SQL_VER}.jre8.jar"
RUN cp -f mssql-jdbc-${SQL_VER}.jre8.jar /tmp/guacamole/lib/sqlserver

### Install precompiled client webapp
RUN wget -O guacamole-${GUAC_VER}.war --span-hosts "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war"


FROM phusion/baseimage:0.9.22

### Version of guacamole to be installed
ENV GUAC_VER 0.9.14

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings
RUN usermod -u 99 nobody && \
    usermod -g 100 nobody && \
    usermod -d /home nobody && \
    chown -R nobody:users /home

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 && \
    add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu xenial main'

### Don't let apt install docs or man pages
COPY excludes /etc/dpkg/dpkg.cfg.d/excludes

### Copy dependency files for Aptitude
COPY /deps/required-deps.txt /deps/required-deps.txt

### Install packages and clean up in one command to reduce build size
RUN apt-get update && \
    xargs -a /deps/required-deps.txt apt-get install -y --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
                            /usr/share/man /usr/share/groff /usr/share/info \
                            /usr/share/lintian /usr/share/linda /var/cache/man && \
    (( find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true )) && \
    (( find /usr/share/doc -empty|xargs rmdir || true )) && \
    rm -R /deps

COPY --from=guacd-build /tmp/guacamole/ /var/lib/guacamole/
COPY --from=guacd-build /tmp/root/ /root/
COPY --from=guacd-build /tmp/guacamole*.war /var/lib/tomcat8/webapps/
COPY --from=guacd-build /usr/local/lib/libguac* /usr/local/lib/
COPY --from=guacd-build /usr/local/lib/freerdp/* /usr/local/lib/freerdp/
COPY --from=guacd-build /usr/local/bin/guacenc /user/local/bin/guacenc
COPY --from=guacd-build /usr/local/sbin/guacd /usr/local/sbin/guacd
COPY --from=guacd-build /etc/init.d/guacd /etc/init.d/guacd
RUN cd /usr/local/lib && \
    ln -s libguac-client-rdp.so.0.0.0 libguac-client-rdp.so && \
    ln -s libguac-client-rdp.so.0.0.0 libguac-client-rdp.so.0 && \
    ln -s libguac-client-ssh.so.0.0.0 libguac-client-ssh.so && \
    ln -s libguac-client-ssh.so.0.0.0 libguac-client-ssh.so.0 && \
    ln -s libguac-client-telnet.so.0.0.0 libguac-client-telnet.so && \
    ln -s libguac-client-telnet.so.0.0.0 libguac-client-telnet.so.0 && \
    ln -s libguac-client-vnc.so.0.0.0 libguac-client-vnc.so && \
    ln -s libguac-client-vnc.so.0.0.0 libguac-client-vnc.so.0 && \
    ln -s libguac.so.12.3.0 libguac.so && \
    ln -s libguac.so.12.3.0 libguac.so.12 && \
    ln -s /usr/local/lib/freerdp/guacai-client.so /usr/lib/x86_64-linux-gnu/freerdp/ && \
    ln -s /usr/local/lib/freerdp/guacdr-client.so /usr/lib/x86_64-linux-gnu/freerdp/ && \
    ln -s /usr/local/lib/freerdp/guacsnd-client.so /usr/lib/x86_64-linux-gnu/freerdp/ && \
    ln -s /usr/local/lib/freerdp/guacsvc-client.so /usr/lib/x86_64-linux-gnu/freerdp/ && \
    update-rc.d guacd defaults && \
    ldconfig && \
    cd /var/lib/tomcat8/webapps && \
    rm -Rf ROOT && \
    ln -s guacamole-$GUAC_VER.war ROOT.war && \
    ln -s guacamole-$GUAC_VER.war guacamole.war

### config directory and classpath directory
RUN mkdir -p /config/guacamole /etc/firstrun

### Tweak my.cnf
RUN sed -i -e 's#\(bind-address.*=\).*#\1 127.0.0.1#g' /etc/mysql/my.cnf && \
    sed -i -e 's#\(log_error.*=\).*#\1 /config/databases/mysql_safe.log#g' /etc/mysql/my.cnf && \
    sed -i -e 's/\(user.*=\).*/\1 nobody/g' /etc/mysql/my.cnf && \
    echo '[mysqld]' > /etc/mysql/conf.d/innodb_file_per_table.cnf && \
    echo 'innodb_file_per_table' >> /etc/mysql/conf.d/innodb_file_per_table.cnf

### Configure Service Startup
COPY rc.local /etc/rc.local
COPY mariadb.sh /etc/service/mariadb/run
COPY firstrun.sh /etc/my_init.d/firstrun.sh
ADD configfiles /etc/firstrun/
RUN chmod a+x /etc/rc.local && \
    chmod +x /etc/service/mariadb/run && \
    chown -R nobody:users /config && \
    chown -R nobody:users /var/log/mysql* && \
    chown -R nobody:users /var/lib/mysql && \
    chown -R nobody:users /etc/mysql && \
    chown -R nobody:users /var/run/mysqld && \
    ln -s /config/guacamole /usr/share/tomcat8/.guacamole

EXPOSE 8080

VOLUME ["/config"]

### END
### To make this a persistent guacamole container, you must map /config of this container
### to a folder on your host machine.
###
