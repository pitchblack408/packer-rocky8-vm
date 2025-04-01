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

VERSION="6.18"
FILENAME="clamtk-${VERSION}-1.el9.noarch.rpm"
URL="https://github.com/dave-theunsub/clamtk/releases/download/v${VERSION}/${FILENAME}"
EXPECTED_SHA="f94a2ec8caeaaffb2683655bcd7d8bb7bc967e6e2dae5a08532b01224737c0a3"


ensure_root
dnf --enablerepo=crb install -y perl-Locale-gettext
verify_installation_by_rpm_qi perl-Locale-gettext perl-Locale-gettext

TMP_DIR=$(mktemp -d)
chmod 755 "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT  # Main trap to clean TMP_DIR

echo "Installing clamtk..."
# Download rpm
RPM_PATH="${TMP_DIR}/${FILENAME}"
download_file "$URL"  "$RPM_PATH"

echo "Verifying clamtk RPM checksum..."
verify_checksha256sum "$RPM_PATH" "$EXPECTED_SHA"

# Scan for malware
if [ "$SCAN" == "true" ]; then
    scan_rpm_file "$RPM_PATH" "$TMP_DIR"
fi

echo "Installing RPM package..."
dnf install -y -q "$RPM_PATH" || { echo "ERROR: Failed to install RPM package."; exit 1; }

# Verify install
verify_installation_by_rpm_qi "clamtk" "clamtk"