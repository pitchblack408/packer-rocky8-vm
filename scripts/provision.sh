#!/bin/bash

TIMEZONE="Etc/UTC"
TOOLS_FILEPATH="/opt/pitchblack408/tools"
DOCKER_CE_VERSION="3:27.3.1-1.el9"
DOCKER_CLI_VERSION="1:27.3.1-1.el9"
GUI="true"
SCAN="true"
VIRTUAL_BOX="false"

timedatectl set-timezone $TIMEZONE
# Set the RTC (hardware clock) to UTC to avoid time drift and conflicts with time zone changes or daylight saving time.
timedatectl set-local-rtc 0

echo '==> Setting '$(timedatectl | grep 'Time zone:' | xargs)

if [ ! -d $TOOLS_FILEPATH ]; then
  mkdir -p $TOOLS_FILEPATH
fi
# The /vagrant folder is mapped to directoy that contains the 
# VagrantFile during vagrant provisioning. 
# But most likely won't be mapped after if VM is used as an appliance.
cp /vagrant/tools/* $TOOLS_FILEPATH
chmod -R +x "$TOOLS_FILEPATH/"*
echo '==> Resetting dnf cache'

dnf -q -y clean all
rm -rf /var/cache/dnf
dnf -q -y makecache &>/dev/null
echo '==> Installing ca-certificates'
if ! dnf --setopt sslverify=false -y -q install ca-certificates &>/dev/null; then
  echo "Failed to install ca-certificates" >&2
  exit 1
fi
echo '==> Updating...'
if ! dnf --setopt sslverify=false -y -q update &>/dev/null; then
  echo "System update failed!" >&2
  exit 1
fi


echo '==> Installing dnf tools'
dnf -q -y install dnf-plugins-core &>/dev/null
dnf -q -y install dnf-plugin-versionlock &>/dev/null

echo '==> Installing Linux tools'
dnf -q -y install epel-release &>/dev/null
dnf -q -y install wireshark-3.4.10-7.el9.x86_64 &>/dev/null
dnf -q -y install putty-0.81-1.el9.x86_64 &>/dev/null
dnf -q -y install p7zip-gui-16.02-31.el9.x86_64 &>/dev/null
dnf -q -y install golang-1.22.9-2.el9_5.x86_64 &>/dev/null
dnf -q -y install ruby-3.0.7-163.el9_5.x86_64 &>/dev/null

echo '==> Installing ClamAV scanner'
dnf -q -y install clamav &>/dev/null
dnf -q -y install clamd &>/dev/null
dnf -q -y install clamav-update &>/dev/null
freshclam
touch /var/log/freshclam.log
chmod 600 /var/log/freshclam.log
chown root /var/log/freshclam.log
systemctl start clamav-freshclam
echo "TCPSocket 3310" >> /etc/clamd.d/scan.conf
echo "TCPAddr 127.0.0.1" >> /etc/clamd.d/scan.conf
echo "LocalSocket /run/clamd.scan/clamd.sock" >> /etc/clamd.d/scan.conf
echo "LogFile /var/log/clamd.scan" >> /etc/clamd.d/scan.conf
systemctl enable clamd@scan
systemctl start clamd@scan

# cp /vagrant/config/bashrc /home/vagrant/.bashrc
# chown vagrant:vagrant /home/vagrant/.bashrc
dnf -q -y install nano tree zip unzip whois &>/dev/null

echo '==> Installing Git'
dnf -q -y install git &>/dev/null
touch /home/vagrant/.gitconfig

echo "==> Installing Python"
dnf install -y -q python &>/dev/null
dnf install -y -q python-pip &>/dev/null
dnf install -y -q python3.12 &>/dev/null
dnf install -y -q python3.12-pip &>/dev/null

echo "=> Adding Hashicorp Repository"
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf update
echo '==> Installing Packer'
dnf -q -y install packer-1.11.2-1 &>/dev/null
dnf versionlock add packer-1.11.2-1
echo '==> Installing Terraform'
dnf -q -y install terraform-1.10.1-1 &>/dev/null
dnf versionlock add terraform-1.10.1-1


echo '==> Removing old docker'
dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc
echo '==> Installing docker'
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf update
dnf install -y docker-ce-$DOCKER_CE_VERSION docker-ce-cli-$DOCKER_CLI_VERSION containerd.io docker-buildx-plugin docker-compose-plugin  &>/dev/null
groupadd docker
usermod -aG docker $USER
newgrp docker
sudo systemctl enable --now docker

echo '==> Installing dive'
if [ -f "$TOOLS_FILEPATH/install_dive.sh" ]; then
     source $TOOLS_FILEPATH/install_dive.sh
else
    echo "File $TOOLS_FILEPATH/install_dive.sh does not exist."
    exit 1
fi

echo '==> Installing powershell'
if [ -f "$TOOLS_FILEPATH/install_powershell.sh" ]; then
     source $TOOLS_FILEPATH/install_powershell.sh
else
    echo "File $TOOLS_FILEPATH/install_powershell.sh does not exist."
    exit 1
fi

echo '==> Installing govmomi and govc'
if [ -f "$TOOLS_FILEPATH/install_govmomi_govc.sh" ]; then
     source $TOOLS_FILEPATH/install_govmomi_govc.sh "$TOOLS_FILEPATH" "$SCAN"
else
    echo "File $TOOLS_FILEPATH/install_govmomi_govc.sh does not exist."
    exit 1
fi

echo '==> Installing VMWare powercli'
if [ -f "$TOOLS_FILEPATH/install_vmware_powercli.sh" ]; then
     source $TOOLS_FILEPATH/install_vmware_powercli.sh
else
    echo "File $TOOLS_FILEPATH/install_vmware_powercli.sh does not exist."
    exit 1
fi

echo '==> Installing ESXi Customizer Powershell'
if [ -f "$TOOLS_FILEPATH/install_esxi_customizer.sh" ]; then
     source $TOOLS_FILEPATH/install_esxi_customizer.sh
else
    echo "File $TOOLS_FILEPATH/install_esxi_customizer.sh does not exist."
    exit 1
fi

echo '==> Installing Balena Etcher'
if [ -f "$TOOLS_FILEPATH/install_balena_etcher.sh" ]; then
     source $TOOLS_FILEPATH/install_balena_etcher.sh
else
    echo "File $TOOLS_FILEPATH/install_balena_etcher.sh does not exist."
    exit 1
fi


echo '==> Installing Ansible Core'
pip3.12 install ansible-core==2.18.1
export PATH="$PATH:/usr/local/bin"
echo "export PATH=\$PATH:/usr/local/bin" >> /etc/profile.d/ansible.sh
echo '==> Installing Ansible Dev Tools'
pip3.12 install ansible-dev-tools==24.12.0


echo '==> Installing OpenJDK'
dnf install -y -q java-21-openjdk-devel.x86_64 &>/dev/null
echo "export JAVA_HOME=$(dirname $(dirname `readlink -f /etc/alternatives/java`))" >> /etc/profile.d/java.sh
echo '==> Installing Gradle'
if [ -f "$TOOLS_FILEPATH/install_gradle.sh" ]; then
     source $TOOLS_FILEPATH/install_gradle.sh
else
    echo "File $TOOLS_FILEPATH/install_gradle.sh does not exist."
    exit 1
fi
echo '==> Installing Maven'
if [ -f "$TOOLS_FILEPATH/install_maven.sh" ]; then
     source $TOOLS_FILEPATH/install_maven.sh
else
    echo "File $TOOLS_FILEPATH/install_maven.sh does not exist."
    exit 1
fi


echo '==> Versions:'
cat /etc/os-release
openssl version || { echo "Failed to get openssl version."; exit 1; }
python --version || { echo "Failed to get python version."; exit 1; }
# python3.12 --version || { echo "Failed to get python version."; exit 1; }
pip --version || { echo "Failed to get pip version."; exit 1; }
curl --version | head -n1 | cut -d '(' -f 1 || { echo "Failed to get curl version."; exit 1; }
git --version || { echo "Failed to get git version."; exit 1; }
/usr/bin/packer --version || { echo "Failed to get packer version."; exit 1; }
terraform --version | head -n1 || { echo "Failed to get terraform version."; exit 1; }
docker --version || { echo "Failed to get docker version."; exit 1; }
ansible --version
wireshark -v || { echo "Failed to get wireshark version."; exit 1; }
go version || { echo "Failed to get go version."; exit 1; }
ruby --version || { echo "Failed to get ruby version."; exit 1; }

echo "==> Locked Versions"
dnf versionlock list
echo "==> Install Gui=$GUI"
if [ "$GUI" == "true" ]; then

  if [ "$VIRTUAL_BOX" == "true" ]; then
      if ls -d /opt/VBoxGuestAdditions-*/ &>/dev/null; then
          echo "The directory /opt/VBoxGuestAdditions exists."
          for dir in /opt/VBoxGuestAdditions-*/; do
              echo "Processing directory: $dir"
              if [ -f "${dir}uninstall.sh" ]; then
                  echo "Running uninstall script in $dir"
                  bash "${dir}uninstall.sh" || { echo "Failed to run uninstall script in $dir"; exit 1; }
              else
                  echo "Uninstall script not found in $dir"
              fi
          done
      else
          echo "The directory VBoxGuestAdditions does not exist."
      fi
      echo '==> Installing VirtualBox Additions Dependencies.'
      error_message=$(dnf install -y bison elfutils-libelf-devel flex gcc glibc-devel glibc-headers kernel-devel kernel-headers libxcrypt-devel libzstd-devel m4 make openssl-devel zlib-devel > /dev/null 2>&1)
      if [ $? -ne 0 ]; then
          echo "Error: Installation failed during installing VirtualBox Additions Dependencies. Reason:"
          echo "$error_message"
          exit 1
      fi
  fi
  echo '==> Installing Visual Studio Code'
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
  dnf check-update
  dnf install -y code
  gsettings set org.gnome.shell favorite-apps "['google-chrome.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop']"

  echo '==> Installing Chrome'
  curl https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -o google-chrome-stable_current_x86_64.rpm
  dnf localinstall -y google-chrome-stable_current_x86_64.rpm
  rm google-chrome-stable_current_x86_64.rpm
  dnf install google-chrome-stable
  
  echo '==> Installing Stig Viewer 3'
  if [ -f "$TOOLS_FILEPATH/install_stig_viewer.sh" ]; then
     source $TOOLS_FILEPATH/install_stig_viewer.sh "$TOOLS_FILEPATH" "$SCAN"
  else
    echo "File $TOOLS_FILEPATH/install_stig_viewer.sh does not exist."
    exit 1
  fi
  echo '==> Installing Rocy Server with GUI'
  error_message=$(dnf group install "Server with GUI" -y > /dev/null 2>&1)
  if [ $? -ne 0 ]; then
      echo "Error: Installation failed. Reason:"
      echo "$error_message"
      exit 1
  fi
  echo '==> Installing ClamTK'
  if [ -f "$TOOLS_FILEPATH/install_clamtk.sh" ]; then
      source $TOOLS_FILEPATH/install_clamtk.sh "$TOOLS_FILEPATH" "$SCAN"
  else
      echo "File $TOOLS_FILEPATH/install_clamtk.sh does not exist."
      exit 1
  fi
  dnf remove -y -q firefox &>/dev/null
  echo '==> Installing Gnome Tweaks'
  dnf install -y -q gnome-tweaks &>/dev/null
  echo '==> Installing Gnome Extensions'
  dnf install -y -q gnome-extensions-app.x86_64 &>/dev/null
  echo '==> Creating Toolbar Favorites'
  TOOLBAR="[org/gnome/shell]\nfavorite-apps=['google-chrome.desktop', 'code.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.Terminal.desktop']\n"
  echo -e $TOOLBAR >> /etc/dconf/db/local.d/00-favorite-apps
  dconf update
  echo '==> Adding Windows Buttons'
  MIN_MAX_BUTTON="[org/gnome/desktop/wm/preferences]\nbutton-layout=':minimize,maximize,close'\n"
  echo -e $MIN_MAX_BUTTON > /etc/dconf/db/local.d/00-minmaxbutton
  dconf update
  echo '==> Adding Gnome Extensions Settings'
  EXTENSIONS="[org/gnome/shell]\nenabled-extensions=['desktop-icons@gnome-shell-extensions.gcampax.github.com', 'window-list@gnome-shell-extensions.gcampax.github.com']\n"
  echo -e $EXTENSIONS > /etc/dconf/db/local.d/00-gnome-shell
  dconf update
  echo '==> Setting Systemctl Default to Graphical'
  systemctl set-default graphical
  systemctl isolate graphical.target
fi
echo '==> Successfully Completed'