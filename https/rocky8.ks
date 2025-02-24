# Kickstart file for Rocky Linux 8

# Install system
install
url --url=http://mirror.rockylinux.org/rocky/8/isos/x86_64/

# Set system language and keyboard layout
lang en_US.UTF-8
keyboard us

# Network configuration
network --bootproto=dhcp --device=eth0 --onboot=yes

# Set the hostname
hostname rocky8vm

# Set root password (in encrypted form)
rootpw --iscrypted $6$examplesalt$7FHLOXszWtrjq9k..9yAfNhgOvD12RcvBpH.vA./pO6OdbF0d2

# Disk partitioning (LVM)
autopart --type=lvm

# Set the system timezone
timezone America/New_York --isUtc

# Package selection
%packages
@core
vim
curl
wget
git
%end

# Reboot after installation
reboot
