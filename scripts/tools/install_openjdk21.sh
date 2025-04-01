#!/bin/bash
dnf install -y -q java-21-openjdk-devel.x86_64 &>/dev/null
echo "export JAVA_HOME=$(dirname $(dirname `readlink -f /etc/alternatives/java`))" >> /etc/profile.d/java.sh