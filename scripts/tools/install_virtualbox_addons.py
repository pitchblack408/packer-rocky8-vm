#!/bin/python


import os
import subprocess
import sys
import argparse
import shutil

REQUIRED_PACKAGES = [
    "bison", "elfutils-libelf-devel", "flex", "gcc", "glibc-devel", "glibc-headers", 
    "kernel-devel", "kernel-headers", "libxcrypt-devel", "libzstd-devel", 
    "m4", "make", "openssl-devel", "zlib-devel"
]

def ensure_root():
    """Ensure the script is run as root."""
    if os.geteuid() != 0:
        print("This script must be run as root!")
        sys.exit(1)

def run_command(command, check=True):
    """Run a command and check for errors."""
    result = subprocess.run(command, shell=True)
    if result.returncode != 0 and check:
        print(f"Command failed: {command}. Exiting.", file=sys.stderr)
        sys.exit(1)
    return result

def check_and_install_packages():
    """Check if required packages are installed, install missing ones."""
    print("Checking for required packages...")

    missing_packages = []
    
    # Check if packages are installed (works for RPM-based systems like CentOS, RHEL)
    for package in REQUIRED_PACKAGES:
        result = subprocess.run(f"dnf list installed {package}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode != 0:
            missing_packages.append(package)

    if missing_packages:
        print(f"The following packages are missing: {', '.join(missing_packages)}")
        print("Attempting to install missing packages...")
        run_command(f"dnf install -y {' '.join(missing_packages)}")

def are_kernel_headers_installed():
    """Check if kernel headers are installed."""
    print("Checking for kernel headers...")
    # Get the current kernel version
    kernel_version = subprocess.check_output("uname -r", shell=True).decode().strip()
    # Check if kernel-devel and kernel-headers are installed
    result = subprocess.run(f"dnf list installed kernel-devel-{kernel_version} kernel-headers-{kernel_version}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        return True
    else:
       return False

def install_kernel_headers():
    """Install kernal headers."""
    # Get the current kernel version
    kernel_version = subprocess.check_output("uname -r", shell=True).decode().strip()
    print("Kernel headers or development files not found. Installing...")
    run_command(f"dnf install -y kernel-devel-{kernel_version} kernel-headers-{kernel_version}")

def clean_old_kernel_headers():
    """Remove old kernel headers and development files."""
    print("Cleaning up old kernel headers and development files...")
    
    # Remove all but the latest kernel headers and development packages
    run_command("dnf remove -y $(dnf repoquery --installonly --latest-limit=-1 -q)")
    print("Old kernel headers cleaned up.")

def check_and_download_iso(iso_url, iso_file):
    """Download the ISO file."""
    if os.path.exists(iso_file):
        print("VirtualBox Guest Additions ISO exists, deleting.")
        os.remove(iso_file)
    print("Downloading VirtualBox Guest Additions ISO...")
    run_command(f"wget -q {iso_url} -O {iso_file}")

def create_directories(mount_dir, target_dir):
    """Create necessary directories."""
    print("Creating directories...")
    os.makedirs(mount_dir, exist_ok=True)
    os.makedirs(target_dir, exist_ok=True)

def mount_iso(iso_file, mount_dir):
    """Mount the ISO file."""
    print("Mounting the ISO...")
    run_command(f"mount -o loop {iso_file} {mount_dir}")

def copy_contents(mount_dir, target_dir):
    """Copy the contents of the mounted ISO."""
    print(f"Copying contents to {target_dir}...")
    run_command(f"cp -r {mount_dir}/* {target_dir}")

def unmount_iso(mount_dir):
    """Unmount the ISO file."""
    print("Unmounting the ISO...")
    run_command(f"umount {mount_dir}")

def clean_up(mount_dir, target_dir, iso_file):
    """Clean up temporary files and directories."""
    print("Cleaning up...")
    os.rmdir(mount_dir)
    os.remove(iso_file)
    shutil.rmtree(target_dir)

def run_guest_additions(target_dir):
    """Run the VBoxLinuxAdditions.run installer."""
    vbox_additions_script = os.path.join(target_dir, "VBoxLinuxAdditions.run")
    
    if os.path.isfile(vbox_additions_script):
        print(f"Running {vbox_additions_script}...")
        run_command(f"{vbox_additions_script}")
    else:
        print("VBoxLinuxAdditions.run not found. Exiting.", file=sys.stderr)
        sys.exit(1)


def prompt_reboot():
    """Prompt the user to reboot the system."""
    reboot = input("The installation is complete. Changes will not take effect until reboot is completed. Would you like to reboot the system now? (y/n): ").strip().lower()
    if reboot == 'y':
        print("Rebooting the system...")
        run_command("reboot")
    else:
        print("Reboot skipped.")


def main():
    parser = argparse.ArgumentParser(description="Install VirtualBox Guest Additions ISO.")
    parser.add_argument('-b', '--virtual-box-version', type=str, required=True, help="The version of VirtualBox manager.")

    args = parser.parse_args()
    iso_url = f"https://download.virtualbox.org/virtualbox/{args.virtual_box_version}/VBoxGuestAdditions_{args.virtual_box_version}.iso"
    iso_file = f"/tmp/VBoxGuestAdditions_{args.virtual_box_version}.iso"
    mount_dir = f"/mnt/iso"
    target_dir = f"/tmp/VBox_GA"
    
    ensure_root()
    check_and_install_packages()
    if not are_kernel_headers_installed():
        install_kernel_headers()  # Kernel headers installation check
        clean_old_kernel_headers()  # Clean up old kernel headers and development files
    check_and_download_iso(iso_url, iso_file)
    create_directories(mount_dir, target_dir)
    mount_iso(iso_file, mount_dir)
    copy_contents(mount_dir, target_dir)
    unmount_iso(mount_dir)
    run_guest_additions(target_dir)
    clean_up(mount_dir, target_dir, iso_file)
    prompt_reboot()
    print("Done!")


if __name__ == "__main__":
    main()
