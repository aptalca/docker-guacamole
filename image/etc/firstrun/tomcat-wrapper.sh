#!/bin/bash
# Source: http://serverfault.com/questions/425132/controlling-tomcat-with-supervisor
function shutdown()
{
    date
    echo "Shutting down Tomcat"
    unset CATALINA_PID # Necessary in some cases
    $CATALINA_HOME/bin/catalina.sh stop
}

date
echo "Starting Tomcat"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export CATALINA_HOME="/usr/share/tomcat9"
export CATALINA_BASE="/var/lib/tomcat9"
export CATALINA_PID="/var/run/tomcat/tomcat9.pid"

. $CATALINA_HOME/bin/catalina.sh start

# Allow any signal which would kill a process to stop Tomcat
trap shutdown HUP INT QUIT ABRT KILL ALRM TERM TSTP

echo "Waiting for `cat $CATALINA_PID`"
wait `cat $CATALINA_PID`