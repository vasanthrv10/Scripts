#!/bin/sh

export JAVA_HOME=/usr/java/jdk1.8.0_321-amd64

cd $JBOSS_HOME/bin
sh jboss-cli.sh --connect ':shutdown' --controller=localhost:9990
