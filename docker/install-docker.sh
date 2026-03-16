#!/bin/bash
# install-docker.sh - Install Docker Engine on Ubuntu
# Reference: https://docs.docker.com/engine/install/ubuntu/
#            https://docs.docker.com/engine/install/linux-postinstall/

set -e

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
  echo "Error: This script is designed for Ubuntu. Detected OS: $ID"
  exit 1
fi

# 1. Remove conflicting packages
echo "Removing conflicting packages..."
sudo apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true

# 2. Set up Docker's apt repository
echo "Setting up Docker apt repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# 3. Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Post-install: non-root access & boot startup
echo "Configuring post-install settings..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER"
newgrp docker

sudo systemctl enable docker.service containerd.service
sudo systemctl start docker

echo "Docker installation complete!"
