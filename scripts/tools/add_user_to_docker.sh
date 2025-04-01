#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo." 
   exit 1
fi

# Function to display usage information
usage() {
    echo "Usage: $0 username"
    exit 1
}

# Ensure a username is provided
if [ -z "$1" ]; then
    usage
fi

USERNAME=$1

groupadd docker
usermod -aG docker $USERNAME
newgrp docker