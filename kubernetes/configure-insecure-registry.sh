#!/bin/bash
# configure-insecure-registry.sh
# Configures containerd to trust a plain HTTP (insecure) private registry.
# Usage: ./configure-insecure-registry.sh <registry-host:port>
# Ref: https://github.com/containerd/containerd/blob/main/docs/hosts.md#bypass-tls-verification-example

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <registry-host:port>"
  exit 1
fi

REGISTRY="$1"

# Ensure containerd is configured to read hosts.toml from /etc/containerd/certs.d
# (containerd config default sets config_path to empty, so it must be set explicitly)
# Ref: https://github.com/containerd/containerd/blob/main/docs/hosts.md#cri
CERTS_DIR="/etc/containerd/certs.d"
CONFIG_TOML="/etc/containerd/config.toml"
if ! grep -q "config_path.*${CERTS_DIR}" "$CONFIG_TOML" 2>/dev/null; then
  echo "Setting config_path in $CONFIG_TOML..."
  sudo sed -i "/\[plugins\..*\.registry\]/,/^\[/ {
    s|config_path\s*=\s*['\"]['\"]|config_path = \"${CERTS_DIR}\"|
  }" "$CONFIG_TOML"
  sudo systemctl restart containerd
fi

# Create the registry-specific hosts.toml
sudo mkdir -p "/etc/containerd/certs.d/${REGISTRY}"

sudo tee "/etc/containerd/certs.d/${REGISTRY}/hosts.toml" > /dev/null <<EOF
server = "http://${REGISTRY}"

[host."http://${REGISTRY}"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

# Note: After config_path is set, subsequent hosts.toml changes take effect without restart.
echo "Done. Pull images with:"
echo "  crictl pull --creds '<username>:<password>' ${REGISTRY}/<image>"
