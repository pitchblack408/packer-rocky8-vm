#!/bin/bash

# Set Gradle version to install
GRADLE_VERSION="8.12"

GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
EXPECTED_SHA="7a00d51fb93147819aab76024feece20b6b84e420694101f276be952e08bef03"
INSTALL_DIR="/opt/gradle"

echo "Installing Gradle version ${GRADLE_VERSION}..."

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo to run it."
    exit 1
fi

# Check if Java is installed
if ! command -v java >/dev/null 2>&1; then
    echo "Java is not installed."
    exit 1
fi

# Install dependencies
if ! command -v wget >/dev/null 2>&1; then
    echo "wget is not installed."
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is not installed."
    exit 1
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum is not installed."
    exit 1
fi

# Download Gradle
TMP_DIR=$(mktemp -d)
echo "Downloading Gradle..."
wget -q -L -O "${TMP_DIR}/gradle.zip" "${GRADLE_URL}"

# Verify checksum
echo "Verifying checksum..."
CALCULATED_SHA=$(sha256sum "${TMP_DIR}/gradle.zip" | awk '{print $1}')
if [[ "${CALCULATED_SHA}" != "${EXPECTED_SHA}" ]]; then
    echo "Checksum verification failed. Expected ${EXPECTED_SHA}, but got ${CALCULATED_SHA}."
    rm -rf "${TMP_DIR}"
    exit 1
fi

# Unpack Gradle
echo "Unpacking Gradle to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"
unzip -qo "${TMP_DIR}/gradle.zip" -d "${INSTALL_DIR}" || { echo "Failed to unpack Gradle. Exiting."; exit 1; }

# Set up symbolic link
ln -sf "${INSTALL_DIR}/gradle-${GRADLE_VERSION}" "${INSTALL_DIR}/latest"

# Configure environment variables
echo "Configuring environment variables..."
cat <<EOF >/etc/profile.d/gradle.sh
export GRADLE_HOME=${INSTALL_DIR}/latest
export PATH=\$GRADLE_HOME/bin:\$PATH
EOF
chmod +x /etc/profile.d/gradle.sh

# Clean up
rm -rf "${TMP_DIR}"

# Verify installation
echo "Verifying Gradle installation..."
source /etc/profile.d/gradle.sh
gradle -v || { echo "Gradle installation failed."; exit 1; }
