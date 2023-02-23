#!/bin/sh

# <----------------- created by @vasanthan ---------------------------->

export JBOSS_HOME=/jboss-eap-7.4.0
export JAVA_HOME=/usr/java/jdk1.8.0_321-amd64
export PATH=$JAVA_HOME/bin:$PATH
export JAVA=$JAVA_HOME/bin/java
rm -rf $JBOSS_HOME/standalone/tmp/*

startdate=($(date "+%y%m%d_%H%M%S"))
touch $JBOSS_HOME/logs/startup_$startdate.out
startuplog=$JBOSS_HOME/logs/startup_$startdate.out
cd $JBOSS_HOME/bin

sh standalone.sh --server-config=standalone-full.xml -b 0.0.0.0 -bmanagement 0.0.0.0 -Djboss.http.port=9089 -Djboss.server.log.dir=$JBOSS_HOME/logs >> $startuplog &

<<ha
sh standalone.sh --server-config=standalone-full.xml -Djboss.http.port=9089 -Djboss.node.name=node1 -b 0.0.0.0 -bmanagement 0.0.0.0 -Djboss.as.management.blocking.timeout=6000 -Djboss.server.log.dir=$JBOSS_HOME/logs -Dauthfilter.options.browserSessionUidCheckEnabled=N -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true -DRTP_REAPER_MEM_USED_PERCENT_ABORT=99 -Djava.awt.headless=true >> $startlog &
ha

echo ""
echo "******************************"
echo "Jboss is starting now, please wait some seconds...."
echo "refer $startuplog for more details about startup process..."
echo "******************************"
echo ""

# <---------------------------------------------------------------------->
