#!/bin/bash


SCRIPTS_ROOT_DIR=$1
SCAN=${SCAN:-${2:-false}}

# Check if SCRIPTS_ROOT_DIR is provided and is a valid directory
if [ -z "$SCRIPTS_ROOT_DIR" ]; then
  echo "ERROR: Must provide the scripts root directory."
  exit 1
elif [ ! -d "$SCRIPTS_ROOT_DIR" ]; then
  echo "ERROR: $SCRIPTS_ROOT_DIR is not a valid directory."
  exit 1
fi
source "$SCRIPTS_ROOT_DIR/dry_install_functions.sh"

# Set versions
VERSION="0.46.3"
GOVMOMI_EXPECTED_SHA="9c83f4a283355ad208fff99c0a699fd81defe10d7df62f99d4a9600931bdcbb7"
GOVC_EXPECTED_SHA="91f96c35a48cdde8c5e661c6c219bdf1303fbefbedcf13eb078b64a194e56d4a"
REQUIRED_CMDS=("curl" "tar" "sha256sum" "dnf")
GOVMOMI_FILENAME="govmomi_${VERSION}_linux_amd64.rpm"
GOVMOMI_URL="https://github.com/vmware/govmomi/releases/download/v${VERSION}/${GOVMOMI_FILENAME}"

GOVC_FILENAME="govc_Linux_x86_64.tar.gz"
GOVC_URL="https://github.com/vmware/govmomi/releases/download/v${VERSION}/${GOVC_FILENAME}"
GOVC_INSTALL_DIR="/usr/local/bin"

# Ensure root privileges
ensure_root
# Check for required commands
check_required_cmds "${REQUIRED_CMDS[@]}"

TMP_DIR=$(mktemp -d)
chmod 755 "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT  # Main trap to clean TMP_DIR

echo "Installing govmomi..."
# Download rpm
GOVMOMI_RPM_PATH="${TMP_DIR}/${GOVMOMI_FILENAME}"
download_file "$GOVMOMI_URL"  "$GOVMOMI_RPM_PATH"

# Verify checksum for govmomi RPM
echo "Verifying govmomi RPM checksum..."
verify_checksha256sum "$GOVMOMI_RPM_PATH" "$GOVMOMI_EXPECTED_SHA"

# Scan for malware
if [ "$SCAN" == "true" ]; then
    scan_rpm_file "$GOVMOMI_RPM_PATH" "$TMP_DIR"
fi

# Clean up RPM file
dnf install -y "$GOVMOMI_RPM_PATH"
rm -f "$GOVMOMI_RPM_PATH" 

# Verify install
verify_installation_by_rpm_qi "govmomi" "govmomi"

# Install govc
echo "Installing govc..."
GOVC_GZIP_PATH="${TMP_DIR}/${GOVC_FILENAME}"
download_file "$GOVC_URL"  "$GOVC_GZIP_PATH"

# Verify checksum for govc tar.gz
echo "Verifying govc tar.gz checksum..."
verify_checksha256sum "$GOVC_GZIP_PATH" "$GOVC_EXPECTED_SHA"

if [ -n "$SCAN" ]; then
    scan_file "$GOVC_GZIP_PATH"
fi

mkdir -p "${TMP_DIR}/extracted"
extract_archive "$GOVC_GZIP_PATH" "${TMP_DIR}/extracted"
chmod +x "${TMP_DIR}/extracted/govc"
mv "${TMP_DIR}/extracted/govc" /usr/local/bin/govc

# Verify installations
echo "Verifying installations..."
verify_installation_by_version "govc version" "govc"
