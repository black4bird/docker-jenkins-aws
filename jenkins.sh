#! /bin/bash

# check if a mysql container is linked.
if [ $MYSQL_PORT_3306_TCP_ADDR != "" ]; then
   mysql -uroot -pmysql -h${MYSQL_PORT_3306_TCP_ADDR} < /tmp/init-base.sql
fi

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
   exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
