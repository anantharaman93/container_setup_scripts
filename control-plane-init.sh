#!/bin/bash
# control-plane-init.sh - Run on the MASTER node ONLY
# Do NOT run this script as root. Run as your standard user.

set -e

# ==========================================
# Variables
# ==========================================
CALICO_VERSION="v3.31.4"
POD_NETWORK_CIDR="192.168.0.0/16"

echo "Starting Kubernetes Control Plane Initialization..."

# ==========================================
# 1. Initialize the Cluster
# ==========================================
echo "Running kubeadm init..."
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR

# ==========================================
# 2. Configure Kubeconfig for Current User
# ==========================================
# Because you are running the script as your standard user, $USER and $HOME map correctly
echo "Setting up kubeconfig for user: $USER"
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Export for current session so kubectl commands below work immediately
export KUBECONFIG="$HOME/.kube/config"

# ==========================================
# 3. Install Calico CNI
# ==========================================
echo "Installing Calico Network Plugin (Version: $CALICO_VERSION)..."

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml

echo "Downloading custom-resources.yaml locally..."
curl -O https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml

kubectl apply -f custom-resources.yaml

# ==========================================
# 4. Output Worker Node Join Command
# ==========================================
echo ""
echo "======================================================================="
echo "Control Plane setup complete!"
echo "Your Calico custom-resources.yaml has been saved to $(pwd)."
echo "======================================================================="
echo "To add worker nodes to this cluster, run common-setup.sh on them,"
echo "and then run the following command:"
echo ""
sudo kubeadm token create --print-join-command
echo ""
echo "======================================================================="
