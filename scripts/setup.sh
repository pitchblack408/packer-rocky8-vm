#!/bin/bash

# Update system and install basic packages
dnf -y update
dnf -y install vim wget curl git

# Set the timezone
timedatectl set-timezone America/New_York

# Add a test user (optional)
useradd testuser
echo "testuser:testpassword" | chpasswd
