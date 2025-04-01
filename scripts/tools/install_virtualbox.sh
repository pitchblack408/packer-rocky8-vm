#!/bin/bash


USERNAME=$1

#VirtualBox-7.0-7.0.20_163906_el9-1.x86_64 
VBOX_PACKAGE="VirtualBox-7.1-7.1.4_165100_el9-1.x86_64"
rpm --import https://www.virtualbox.org/download/oracle_vbox.asc
dnf config-manager --add-repo https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
dnf makecache
dnf install -y $VBOX_PACKAGE

usermod -aG vboxusers $USERNAME
