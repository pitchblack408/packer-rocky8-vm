#!/bin/bash

# Variables
DIVE_VERSION="0.12.0"
DIVE_URL="https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.rpm"
DIVE_RPM="dive_${DIVE_VERSION}_linux_amd64.rpm"
EXPECTED_SHA="28a002edf463a74ae954c9ce9af40095f4adf5942b4ce7d32a51e4da9fbd5e7b"

echo "Installing Dive version ${DIVE_VERSION}..."

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo to run it."
    exit 1
fi

# Check if curl or wget is installed
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "Neither curl nor wget is installed. Please install one of them to proceed."
    exit 1
fi

# Check if sha256sum is installed
if ! command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum is not installed. Please install it to proceed."
    exit 1
fi

# Download Dive
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

echo "Downloading Dive..."
if command -v curl >/dev/null 2>&1; then
    curl -LO "${DIVE_URL}" || { echo "Failed to download Dive. Exiting."; exit 1; }
elif command -v wget >/dev/null 2>&1; then
    wget "${DIVE_URL}" || { echo "Failed to download Dive. Exiting."; exit 1; }
fi

# Verify checksum
echo "Verifying checksum..."
CALCULATED_SHA=$(sha256sum "${DIVE_RPM}" | awk '{print $1}')
if [[ "${CALCULATED_SHA}" != "${EXPECTED_SHA}" ]]; then
    echo "Checksum verification failed. Expected ${EXPECTED_SHA}, but got ${CALCULATED_SHA}."
    rm -rf "$TMP_DIR"
    exit 1
fi
echo "Checksum verification passed."

# Install Dive
echo "Installing Dive..."
dnf install -y -q "${DIVE_RPM}" || { echo "Failed to install Dive. Exiting."; exit 1; }

# Clean up
cd || exit 1
rm -rf "$TMP_DIR"

# Verify installation
if command -v dive >/dev/null 2>&1; then
    echo "Dive version ${DIVE_VERSION} installed successfully."
else
    echo "Dive installation failed."
    exit 1
fi
