#!/bin/bash

set -ouex pipefail

### Enable/Add repos

# Add Netbird repo
tee /etc/yum.repos.d/netbird.repo <<EOF
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=0
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# Add bazzite-multilib copr
tee /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib.repo <<EOF
[copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib]
name=Copr repo for bazzite-multilib owned by bazzite-org
baseurl=https://download.copr.fedorainfracloud.org/results/bazzite-org/bazzite-multilib/fedora-\$releasever-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/bazzite-org/bazzite-multilib/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

# Enable Terra repository, credit to ublue for this code
terra_repo="/etc/yum.repos.d/terra.repo"
if (! grep -q "enabled=0" "$terra_repo"); then
  echo "Terra repository already enabled."
else
  echo "Enabling Terra Repository."
  sed -i 's@enabled=0@enabled=1@g' "$terra_repo"
fi

### Install dnf-plugins-core for required commands

dnf5 install -y dnf-plugins-core

### Remove unwanted packages

dnf5 remove -y krunner-bazaar \
  bazaar \
  ptyxis

### Install packages

# install discover, exclude packages that cause issues
dnf5 install -y plasma-discover \
  plasma-discover-flatpak \
  plasma-discover-notifier \
  plasma-discover-kns \
  --exclude=plasma-discover-offline-updates,plasma-discover-packagekit,plasma-discover-rpm-ostree,packagekit

# install other packages
dnf5 install -y podman-compose \
  zsh \
  util-linux \
  vlc \
  vlc-plugin-gstreamer \
  vlc-plugin-ffmpeg \
  vlc-plugin-pipewire \
  vlc-plugins-all \
  konsole \
  neovim \
  htop

# install from bazzite-multilib copr
dnf5 -y install --repo="copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib" \
  pipewire-config-raop

# using rpm-ostree over dnf here as dnf had issues properly installing
# these packages.
rpm-ostree install -y netbird netbird-ui coolercontrol liquidctl

### Enable services

# enable podman socket
systemctl enable podman.socket

# enable netbird system service
systemctl enable netbird

# enable coolercontrold
systemctl enable coolercontrold
