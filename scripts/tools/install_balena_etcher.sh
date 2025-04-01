#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

VERSION="1.19.25"
RPM_URL="https://github.com/balena-io/etcher/releases/download/v${VERSION}/balena-etcher-${VERSION}-1.x86_64.rpm"
RPM_FILE="/tmp/balena-etcher-${VERSION}-1.x86_64.rpm"
EXPECTED_SHA="bfa0acc5de4e1f4d6417aadd1a421beb63ea3118960c72e5c86af52ad927e7c9"

# Download the Balena Etcher RPM file
echo "Downloading Balena Etcher RPM package from $RPM_URL..."
curl -L -o $RPM_FILE $RPM_URL
if [[ ! -f $RPM_FILE ]]; then
    echo "Error: Failed to download Balena Etcher RPM package. Exiting."
    exit 1
fi

# Verify the downloaded RPM file's SHA256 checksum
echo "Verifying the checksum of the downloaded file..."
DOWNLOAD_SHA=$(sha256sum $RPM_FILE | cut -d ' ' -f 1)

if [[ "$DOWNLOAD_SHA" != "$EXPECTED_SHA" ]]; then
    echo "Error: Checksum mismatch! Expected $EXPECTED_SHA but got $DOWNLOAD_SHA. Exiting."
    rm -f $RPM_FILE
    exit 1
fi

echo "Checksum verified successfully."

# Install the RPM package using dnf
echo "Installing Balena Etcher..."
dnf install -y $RPM_FILE
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to install Balena Etcher. Exiting."
    exit 1
fi

# Verify installation success
rpm -qi balena-etcher || { echo "Balena Etcher installation failed."; exit 1; }

# Clean up the downloaded RPM file
rm -f $RPM_FILE

# Provide success message
echo "Balena Etcher has been successfully installed."
