Guacamole
====

Dockerfile for Guacamole 0.9.13 with embedded MariaDB (MySQL) and LDAP authentication

Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC and RDP.

---
Author
===

Based on the work of Zuhkov <zuhkov@gmail.com> and aptalca 
Updated by Jason Bean to the latest version of guacamole

---
Building
===

Build from docker file:

```
git clone git@github.com:jason-bean/docker-guacamole.git
docker build -t jasonbean/guacamole .
```

You can also obtain it via:  

```
docker pull jasonbean/guacamole
```

---
Running
===

Create your guacamole config directory (which will contain both the properties file and the database).

To run using MariaDB for user authentication, launch with the following:

```
docker run -d -v /your-config-location:/config -p 8080:8080 -e OPT_MYSQL=Y jasonbean/guacamole
```

Browse to ```http://your-host-ip:8080``` and login with user and password `guacadmin`

---
Credits
===

Apache Guacamole copyright The Apache Software Foundation, Licenced under the Apache License, Version 2.0.

This docker image is built upon the baseimage made by phusion and forked from hall/guacamole, and further forked from Zuhkov/docker-containers and then aptalca/docker-containers
