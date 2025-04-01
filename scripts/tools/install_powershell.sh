#!/bin/bash

# Script to install PowerShell on Red Hat-based Linux systems

# Variables
VERSION="7.4.6"
RPM_PACKAGE="powershell-${VERSION}-1.rh.x86_64.rpm"
POWERSHELL_RPM_URL="https://github.com/PowerShell/PowerShell/releases/download/v${VERSION}/${RPM_PACKAGE}"
EXPECTED_SHA="bf5ebf66702561b42005295b1d00685cc90d98706ce23c53f10a3bd8ad550682"
REQUIRED_CMDS=("wget" "curl" "tar" "gzip" "sha256sum" "dnf")

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Check for required commands
echo "Checking for required dependencies..."
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and rerun the script."
        exit 1
    fi
done
echo "All required dependencies are present."

# Download PowerShell RPM package
echo "Downloading PowerShell RPM package..."
if ! wget -q $POWERSHELL_RPM_URL -O $RPM_PACKAGE; then
    echo "Error: Failed to download the PowerShell RPM package."
    exit 1
fi

# Verify checksum
echo "Verifying checksum..."
DOWNLOADED_SHA=$(sha256sum $RPM_PACKAGE | awk '{print $1}')
if [[ $DOWNLOADED_SHA != $EXPECTED_SHA ]]; then
    echo "Checksum verification failed!"
    echo "Expected: $EXPECTED_SHA"
    echo "Got: $DOWNLOADED_SHA"
    rm -f $RPM_PACKAGE
    exit 1
fi
echo "Checksum verification passed."

# Install PowerShell
echo "Installing PowerShell..."
if ! dnf install -y ./$RPM_PACKAGE; then
    echo "Error: Failed to install PowerShell."
    rm -f $RPM_PACKAGE
    exit 1
fi

# Clean up
echo "Cleaning up..."
rm -f $RPM_PACKAGE

# Verify installation
echo "Verifying PowerShell installation..."
if ! pwsh --version; then
    echo "Error: PowerShell installation verification failed."
    exit 1
fi

echo "PowerShell installation is complete."
