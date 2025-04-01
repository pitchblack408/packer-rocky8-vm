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

# Variables
APP_VERSION="3-4-0"
APP_NAME="stigviewer"
APP_FILENAME="U_STIGViewer-linux_x64-3-4-0.zip"
APP_URL="https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_STIGViewer-linux_x64-${APP_VERSION}.zip"
EXPECTED_SHA="39debcb9c75fd9e7da2bf4e2bb38fc65a64cb6a43b58dac20d46f9c9726e4a22"
INSTALL_DIR="/opt/${APP_NAME}"


#Icon
ICON_URL="https://public.cyber.mil/wp-content/uploads/home/img/cropped-DoD-Cyber-Exchange-Mark-1-32x32.png"

#Launcher Variables
LAUNCHER_APP_NAME="STIG Viewer 3"
LAUNCHER_APP_PATH="/opt/stigviewer/STIG Viewer 3"
LAUNCHER_ICON_PATH="/opt/stigviewer/stigviewer-icon.png"  # Change this if you have an icon
LAUNCHER_DESKTOP_FILE_PATH="/usr/share/applications/stigviewer3.desktop"  # System-wide installation

REQUIRED_CMDS=("curl" "unzip" "sha256sum" "dnf")

# Ensure root privileges
ensure_root
# Check for required commands
check_required_cmds "${REQUIRED_CMDS[@]}"

TMP_DIR=$(mktemp -d)
chmod 755 "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT  # Main trap to clean TMP_DIR

echo "Installing Stig Viewer..."
# Download
ARCHIVE_PATH="${TMP_DIR}/${APP_FILENAME}"
download_file "$APP_URL"  "$ARCHIVE_PATH"

# Verify checksum
echo "Verifying checksum..."
verify_checksha256sum "$ARCHIVE_PATH" "$EXPECTED_SHA"

# Scan for malware
if [ "$SCAN" == "true" ]; then
    scan_file "$ARCHIVE_PATH" "$TMP_DIR"
fi

mkdir -p "${TMP_DIR}/extracted"
extract_archive "$ARCHIVE_PATH" "${TMP_DIR}/${APP_NAME}"
EXTRACTED_DIR=$(find "${TMP_DIR}/${APP_NAME}" -maxdepth 1 -type d -name 'stig_viewer_*' | head -n 1)
# echo $EXTRACTED_DIR
# Move the binary to the install directory
echo "Installing ${APP_NAME} to ${INSTALL_DIR}..."
mkdir -p ${INSTALL_DIR}
# echo "${EXTRACTED_DIR}/*"
# echo "${INSTALL_DIR}/"
cp -fr "${EXTRACTED_DIR}/"* "${INSTALL_DIR}"

download_file "$ICON_URL" "$LAUNCHER_ICON_PATH"
chmod 644 "$LAUNCHER_ICON_PATH"
# Check if the icon exists
if [[ ! -f "$LAUNCHER_ICON_PATH" ]]; then
    echo "Warning: Icon file '$LAUNCHER_ICON_PATH' does not exist. Consider providing a valid icon."
fi

# Creating Launcher
cat > "$LAUNCHER_DESKTOP_FILE_PATH" <<EOF
[Desktop Entry]
Name=$LAUNCHER_APP_NAME
Comment=Security Technical Implementation Guide Viewer
Exec="$LAUNCHER_APP_PATH"
Icon=$LAUNCHER_ICON_PATH
Terminal=false
Type=Application
Categories=Utility;Security;
EOF

# Make the .desktop file executable
chmod +x "$LAUNCHER_DESKTOP_FILE_PATH"

# Provide feedback
echo "Launcher created at $LAUNCHER_DESKTOP_FILE_PATH"
echo "You should now be able to find '$LAUNCHER_APP_NAME' in the application menu for all users."
