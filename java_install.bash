#! /usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "This script must be ran with sudo permissions. Exiting due to insufficent perms."
    exit
fi


COMP_YEAR=2023
JAVA_REL=17

set -ex
apt-get install -y --no-install-recommends openjdk-$JAVA_REL-jdk-headless
(javac -version | grep -q "javac $JAVA_REL.*") || exit

JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | grep -oh '\/.*\w') 
mkdir -p /home/system/wpilib/$COMP_YEAR/jdk && ln -s $JAVA_HOME "/home/system/wpilib/$COMP_YEAR/jdk"
echo "Java installed at $JAVA_HOME" 