#! /usr/bin/env bash

if [ $UID -ne 0 ]; then
    echo "This script must be ran with sudo permissions. Exiting due to insufficent perms."
    exit
fi

source /home/system/wpi_codespace/.env
source /home/system/wpi_codespace/config.conf

set -ex
apt-get install -y --no-install-recommends openjdk-$JAVA_REL-jdk-headless
(javac -version | grep -q "javac $JAVA_REL.*") || exit

JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | grep -oh '\/.*\w') 
mkdir -p /home/system/wpilib/$COMP_YEAR && cd /home/system/wpilib/$COMP_YEAR
ln -s $JAVA_HOME jdk
echo "Java installed at $JAVA_HOME" 