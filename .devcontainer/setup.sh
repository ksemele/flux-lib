#!/bin/bash
set -euo pipefail

KIND_VERSION="v0.31.0"
FLUX_VERSION="v2.8.1"

# Install kind
curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind

# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo VERSION="${FLUX_VERSION}" bash

# Create kind cluster
if ! kind get clusters | grep -q "^flux$"; then
  kind create cluster --name flux --config .devcontainer/kind-cluster.yaml
  flux install
else
  echo "Cluster 'flux' already exists, skipping creation"
fi

# Verify tools
kubectl version
helm version
flux --version
