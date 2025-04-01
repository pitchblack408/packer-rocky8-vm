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
HOMEDIR="/home/$USERNAME"
DEFAULT_SHELL="/bin/bash"

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
    exit 1
fi

# Create the user and their home directory
useradd -m -d "$HOMEDIR" -s "$DEFAULT_SHELL" "$USERNAME"

# Check if useradd succeeded
if [ $? -ne 0 ]; then
    echo "Failed to create user '$USERNAME'."
    exit 1
fi

echo "User '$USERNAME' created successfully."

# Set a password for the user
echo "Please set a password for the new user:"
passwd "$USERNAME"

# Ensure proper permissions for the home directory
chown -R "$USERNAME:$USERNAME" "$HOMEDIR"
chmod 700 "$HOMEDIR"

echo "Home directory permissions set for '$HOMEDIR'."

# Create some default files in the user's home directory
echo "Creating default configuration files..."
cat <<EOL > "$HOMEDIR/.bashrc"
# .bashrc

# User specific aliases and functions
alias ll='ls -la'
alias grep='grep --color=auto'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
EOL

cat <<EOL > "$HOMEDIR/.bash_profile"
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
PATH=\$PATH:\$HOME/bin
export PATH
EOL

# Set ownership and permissions for the default files
chown "$USERNAME:$USERNAME" "$HOMEDIR/.bashrc" "$HOMEDIR/.bash_profile"
chmod 644 "$HOMEDIR/.bashrc" "$HOMEDIR/.bash_profile"

echo "Default configuration files created."

# Optionally add the user to common groups
usermod -aG wheel "$USERNAME"
echo "User '$USERNAME' added to 'wheel' group for sudo privileges (if applicable)."

# Add the user to the docker group
if getent group docker &>/dev/null; then
    usermod -aG docker "$USERNAME"
    echo "User '$USERNAME' added to the 'docker' group."
else
    echo "Docker group does not exist. Ensure Docker is installed and the group is created."
fi

echo "User '$USERNAME' setup is complete."
