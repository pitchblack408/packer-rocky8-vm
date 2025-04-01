#!/bin/bash

# Set Maven version to install
MAVEN_VERSION="3.9.9"
MAVEN_URL="https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
EXPECTED_512_SHA="a555254d6b53d267965a3404ecb14e53c3827c09c3b94b5678835887ab404556bfaf78dcfe03ba76fa2508649dca8531c74bca4d5846513522404d48e8c4ac8b"
INSTALL_DIR="/opt/maven"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo to run it."
    exit 1
fi

# Install dependencies
if ! command -v wget >/dev/null 2>&1; then
    echo "wget is not installed."
    exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
    echo "tar is not installed."
    exit 1
fi
if ! command -v sha512sum >/dev/null 2>&1; then
    echo "sha512sum is not installed."
    exit 1
fi

echo "Installing Apache Maven version ${MAVEN_VERSION}..."

# Download Maven
TMP_DIR=$(mktemp -d)
echo "Downloading Maven..."
wget -q -O "${TMP_DIR}/maven.tar.gz" "${MAVEN_URL}" || { echo "Failed to download Maven. Exiting."; exit 1; }

# Verify checksum
echo "Verifying checksum..."
CALCULATED_SHA=$(sha512sum "${TMP_DIR}/maven.tar.gz" | awk '{print $1}')
if [[ "${CALCULATED_SHA}" != "${EXPECTED_512_SHA}" ]]; then
    echo "SHA-512 checksum verification failed!"
    echo "Expected: ${EXPECTED_512_SHA}"
    echo "Got: ${CALCULATED_SHA}"
    rm -rf "${TMP_DIR}"
    exit 1
fi

# Unpack Maven
echo "Unpacking Maven to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"
tar -xzf "${TMP_DIR}/maven.tar.gz" -C "${INSTALL_DIR}" || { echo "Failed to unpack Maven. Exiting."; exit 1; }

# Set up symbolic link
ln -sf "${INSTALL_DIR}/apache-maven-${MAVEN_VERSION}" "${INSTALL_DIR}/latest"

# Configure environment variables
echo "Configuring environment variables..."
cat <<EOF >/etc/profile.d/maven.sh
export M2_HOME=${INSTALL_DIR}/latest
export MAVEN_HOME=${INSTALL_DIR}/latest
export PATH=\$M2_HOME/bin:\$PATH
EOF
chmod +x /etc/profile.d/maven.sh

# Clean up
rm -rf "${TMP_DIR}"

# Verify installation
echo "Verifying Maven installation..."
source /etc/profile.d/maven.sh
mvn -v || { echo "Maven installation failed."; exit 1; }

