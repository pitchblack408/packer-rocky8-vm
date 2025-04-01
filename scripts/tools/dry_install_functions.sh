#!/bin/bash

# Function to display an error message and exit
function error_exit() {
    echo "ERROR: $1"
    exit 1
}

function check_command() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        error_exit "File and expected checksum must be provided."
    fi
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error_exit "$cmd must be installed."
    fi
}

function check_required_cmds() {
    local required_cmds=$1
    # Check for required commands
    echo "Checking for required dependencies..."
    for cmd in "${required_cmds[@]}"; do
        if ! command -v $cmd &>/dev/null; then
            error_exit "The $cmd is not installed. Please install it and rerun the script."
        fi
    done
    echo "All required dependencies are present."
}

# Ensure the script is run as root
function ensure_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
  fi
}

# Function to download a file
function download_file() {
    local url="$1"
    local filepath="$2"
    check_command curl
    if [ -z "$url" ] || [ -z "$filepath" ]; then
        error_exit "The URL and filepath must be provided."
    fi
    echo "Downloading $url..."
    curl -L -o "$filepath" "$url" || error_exit "Failed to download $url. Exiting."
}

# Extracts tarballs and zips
extract_archive() {
    local archive="$1"
    local extracted_dir="$2"
    if [ -z "$archive" ] || [ -z "$extracted_dir" ]; then
      error_exit "The URL and filepath must be provided."
    fi 
    if file "$archive" | grep -q "gzip compressed"; then
      check_command tar
      tar -xzf "$archive" -C "$extracted_dir"
    elif file "$archive" | grep -q "tar archive"; then
      check_command tar
      tar -xf "$archive" -C "$extracted_dir"
    elif file "$archive" | grep -q "Zip archive"; then
      check_command unzip
      unzip -q "$archive" -d "$extracted_dir"
    else
      error_exit "Unsupported archive format: $archive"
    fi
}

# Function to verify checksum
function verify_checksha256sum() {
    local file=$1
    local expected_sha=$2
    if [ -z "$file" ] || [ -z "$expected_sha" ]; then
        error_exit "File and expected checksum must be provided."
    fi
    local downloaded_sha=$(sha256sum "$file" | cut -d ' ' -f 1)
    if [[ "$downloaded_sha" != "$expected_sha" ]]; then
        error_exit "Checksum mismatch! Expected $expected_sha but got $downloaded_sha. Exiting."
    fi
    echo "Checksum verified successfully."
}

# Function to install an RPM package
function install_rpm() {
    local rpm_file=$1
    if [ -z "$rpm_file" ]; then
        error_exit "RPM file must be provided."
    fi
    echo "Installing $rpm_file..."
    dnf install -y "$rpm_file" || error_exit "Failed to install $rpm_file. Exiting."
}


# Function to verify the installation using version command
function verify_installation_by_version() {
    local get_version_cmd=$1
    local application_name=$2
    if [ -z "$get_version_cmd" ] || [ -z "$application_name" ]; then
        error_exit "Version command and application name must be provided."
    fi
    $get_version_cmd || error_exit "$application_name installation failed."
}

# Function to verify the installation using rpm -qi
function verify_installation_by_rpm_qi() {
    local rpm_package_name=$1
    local application_name=$2
    if [ -z "$rpm_package_name" ] || [ -z "$application_name" ]; then
        error_exit "RPM package name and application name must be provided."
    fi
    rpm -qi "$rpm_package_name" || error_exit "$application_name installation failed."
}

# Function to scan the RPM package for malware
function scan_rpm_file() {
    local rpm_filepath=$1
    local tmp_dir=$2  # Use the passed tmp_dir

    if [ -z "$rpm_filepath" ] || [ -z "$tmp_dir" ]; then
        error_exit "The parameter rpm_filepath or tmp_dir was  not provided. Exiting."
    fi
    for cmd in clamdscan rpm2cpio cpio; do
        command -v $cmd &>/dev/null || error_exit "$cmd is not installed. Exiting."
    done
    echo "Extracting $rpm_filepath..."
    (rpm2cpio "$rpm_filepath" | cpio -idmv $tmp_dir) || error_exit "Failed to extract RPM file. Exiting."
    echo "Scanning extracted files for malware..."
    scan_output=$(clamdscan --no-summary "$tmp_dir")  # Capture the output of clamdscan
    local scan_status=$?
    # Analyze the scan result
    if [ $scan_status -eq 0 ]; then
        echo "No malware detected in extracted files."
    elif [ $scan_status -eq 1 ]; then
        echo "Malware detected in extracted files."
        echo "$scan_output"  # Print the full scan output
        error_exit "Malware detected in extracted files. Exiting."
    elif [ $scan_status -eq 2 ]; then
        echo "Error during scan. Output:"
        echo "$scan_output"  # Print the full scan output
        error_exit "Clamdscan encountered an error. Exiting."
    else
        error_exit "Unknown error with clamdscan. Exiting."
    fi
}


# Function to scan files other than RPMs
function scan_file() {
    local file=$1
    if [ -z "$file" ]; then
        error_exit "No file provided. Exiting."
    fi
    command -v clamdscan &>/dev/null || error_exit "ClamAV is not installed. Exiting."
    echo "Scanning file: $file"
    clamdscan --no-summary "$file" || error_exit "Malware detected in file. Exiting."
    echo "File scanned and no malware detected."
}
