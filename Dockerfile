### Dockerfile for guacamole
### Includes the mysql authentication module preinstalled

# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.

ARG DEBIAN_VERSION=stable
##########################
### Get Guacamole Server
ARG GUAC_VER=1.0.0
FROM guacamole/guacd:${GUAC_VER} AS guacd

##########################################
### Build Guacamole Client
### Use official maven image for the build
FROM maven:3-jdk-8 AS guacamole

ARG GUAC_VER=1.0.0

### Use args to build radius auth extension such as
### `--build-arg BUILD_PROFILE=lgpl-extensions`
ARG BUILD_PROFILE

# Build environment variables
ENV BUILD_DIR=/tmp/guacamole-docker-BUILD

ADD https://github.com/apache/guacamole-client/archive/${GUAC_VER}.tar.gz /tmp

RUN mkdir -p ${BUILD_DIR}                                && \
    tar -C /tmp -xzf /tmp/${GUAC_VER}.tar.gz             && \
    ls -al /tmp                                          && \
    mv /tmp/guacamole-client-${GUAC_VER}/* ${BUILD_DIR}

WORKDIR ${BUILD_DIR}

### Add configuration scripts
RUN mkdir -p /opt/guacamole/bin && cp -R guacamole-docker/bin/* /opt/guacamole/bin/

### Run the build itself
RUN /opt/guacamole/bin/build-guacamole.sh "$BUILD_DIR" /opt/guacamole "$BUILD_PROFILE"

COPY cpexts.sh /opt/guacamole/bin
RUN chmod +x /opt/guacamole/bin/cpexts.sh  && /opt/guacamole/bin/cpexts.sh "$BUILD_DIR" /opt/guacamole


####################
### Build Main Image

###############################
### Build image without MariaDB
FROM debian:${DEBIAN_VERSION} AS nomariadb

ARG SERVER_PREFIX_DIR=/usr/local/guacamole
ARG CLIENT_PREFIX_DIR=/opt/guacamole

### Set correct environment variables.
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LD_LIBRARY_PATH=${SERVER_PREFIX_DIR}/lib
ENV GUACD_LOG_LEVEL=info

### Configure user nobody to match unRAID's settings
RUN usermod -u 99 nobody         && \
    usermod -g 100 nobody        && \
    usermod -d /home nobody      && \
    chown -R nobody:users /home

### Don't let apt install docs or man pages
COPY excludes /etc/dpkg/dpkg.cfg.d/excludes

### Copy build artifacts into this stage
COPY --from=guacd ${SERVER_PREFIX_DIR} ${SERVER_PREFIX_DIR}
COPY --from=guacamole ${CLIENT_PREFIX_DIR} ${CLIENT_PREFIX_DIR}

ARG RUNTIME_DEPENDENCIES="      \
    supervisor                  \
    tomcat8                     \
    pwgen                       \
    ghostscript                 \
    libfreerdp-plugins-standard \
    fonts-liberation            \
    fonts-dejavu                \
    xfonts-terminus             \
    fonts-powerline             \
    tzdata                      \
    procps"

### Install packages and clean up in one command to reduce build size
RUN apt-get update                                                                                                                              && \
    apt-get install -y --no-install-recommends $RUNTIME_DEPENDENCIES                                                                            && \
    apt-get install -y --no-install-recommends $(cat "${SERVER_PREFIX_DIR}"/DEPENDENCIES)                                                       && \
    rm -rf /var/lib/apt/lists/*

ADD image /

### Link FreeRDP plugins into proper path
RUN ${SERVER_PREFIX_DIR}/bin/link-freerdp-plugins.sh ${SERVER_PREFIX_DIR}/lib/freerdp/guac*.so

### Configure Service Startup
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN rm -Rf /var/lib/tomcat8/webapps/ROOT                                            && \
    cp ${CLIENT_PREFIX_DIR}/guacamole.war /var/lib/tomcat8/webapps/guacamole.war    && \
    ln -s /var/lib/tomcat8/webapps/guacamole.war /var/lib/tomcat8/webapps/ROOT.war  && \
    chmod +x /etc/firstrun/*.sh                                                     && \
    chmod +x /bin/tini                                                              && \
    mkdir -p /config/Guacamole /config/log/tomcat8 /var/lib/tomcat8/temp            && \
    ln -s /config/guacamole /etc/guacamole                                          && \
    chown -R root:root /config/log/tomcat8                                          && \
    rmdir /var/log/tomcat8                                                          && \
    ln -s /config/log/tomcat8 /var/log/tomcat8

EXPOSE 8080

VOLUME ["/config"]

CMD [ "/etc/firstrun/firstrun.sh" ]


############################
### Build image with MariaDB 
FROM nomariadb

RUN apt-get update                                                                                                                              && \
    apt-get install -y --no-install-recommends dirmngr gnupg                                                                                    && \
    apt-key adv --no-tty --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8                                                        && \
    echo 'deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.2/debian stretch main' >> /etc/apt/sources.list    && \
    apt-get update                                                                                                                              && \
    apt-get install -y --no-install-recommends mariadb-server                                                                                   && \
    rm -rf /var/lib/apt/lists/*

ADD image-mariadb /

### Tweak my.cnf & Change Folder Permissions
RUN sed -i -e 's#\(datadir.*=\).*#\1 /config/databases#g' /etc/mysql/my.cnf                         && \
    sed -i -e 's#\(bind-address.*=\).*#\1 127.0.0.1#g' /etc/mysql/my.cnf                            && \
    sed -i -e '/log_warnings.*=.*/a log_error = /config/databases/mysql_safe.log' /etc/mysql/my.cnf && \
    sed -i -e 's/\(user.*=\).*/\1 nobody/g' /etc/mysql/my.cnf                                       && \
    echo '[mysqld]' > /etc/mysql/conf.d/innodb_file_per_table.cnf                                   && \
    echo 'innodb_file_per_table' >> /etc/mysql/conf.d/innodb_file_per_table.cnf                     && \
    chown -R nobody:users /config                                                                   && \
    chown -R nobody:users /var/log/mysql*                                                           && \
    chown -R nobody:users /var/lib/mysql                                                            && \
    chown -R nobody:users /etc/mysql                                                                && \
    chown -R nobody:users /var/run/mysqld                                                           && \
    chmod +x /etc/firstrun/*.sh

### END
### To make this a persistent guacamole container, you must map /config of this container
### to a folder on your host machine.
###
