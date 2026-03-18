#!/bin/bash
# common-setup.sh - Run on ALL nodes (Master & Workers)
# Do NOT run this script as root. Run as your standard user; it will prompt for sudo when necessary.
#
# References:
#   Kubernetes container runtimes:  https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#   kubeadm install guide:          https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#   containerd getting started:     https://github.com/containerd/containerd/blob/main/docs/getting-started.md
#   crictl documentation:           https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md

set -e

# ==========================================
# Pre-Flight: OS Compatibility Check
# ==========================================
source /etc/os-release
if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
  echo "Error: This script is designed for Ubuntu or Debian. Detected OS: $ID"
  exit 1
fi

# ==========================================
# Variables
# ==========================================
K8S_VERSION="1.35.0"
# Extract minor version (e.g., 1.35) for the apt repository URL
K8S_MINOR_VERSION=$(echo "$K8S_VERSION" | cut -d. -f1,2)

echo "Starting Kubernetes Common Setup for $NAME $VERSION_CODENAME..."

# ==========================================
# 1. System Prep: Swap & Kernel Modules
# Ref: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisites
# Ref: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin
# ==========================================
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf > /dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# ==========================================
# 2. Install Container Runtime (containerd)
# Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository  (containerd.io package)
# Ref: https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md
# ==========================================
echo "Installing containerd..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg apt-transport-https

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Allow non-root users to access the containerd socket via a "containerd" group
# Ref: https://github.com/containerd/containerd/blob/main/docs/man/containerd-config.toml.5.md  (gid option under [grpc])
echo "Setting up containerd group for non-root socket access..."
sudo groupadd -f containerd
sudo usermod -aG containerd "$USER"
CONTAINERD_GID=$(getent group containerd | cut -d: -f3)
sudo sed -i "s/^\(\s*\)gid = 0/\1gid = $CONTAINERD_GID/" /etc/containerd/config.toml
newgrp containerd

sudo systemctl restart containerd
sudo systemctl enable containerd

# ==========================================
# 3. Configure crictl
# Ref: https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md
# ==========================================
cat <<EOF | sudo tee /etc/crictl.yaml > /dev/null
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

# ==========================================
# 4. Install Kubernetes Components
# Ref: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
# ==========================================
echo "Installing kubeadm, kubelet, and kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR_VERSION}/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
# Use a wildcard to catch the exact OS package suffix (e.g., 1.35.0-1.1)
sudo apt-get install -y kubelet=${K8S_VERSION}-* kubeadm=${K8S_VERSION}-* kubectl=${K8S_VERSION}-*

sudo apt-mark hold kubelet kubeadm kubectl

echo "Common setup complete! Proceed to run control-plane-init.sh on the master node."
