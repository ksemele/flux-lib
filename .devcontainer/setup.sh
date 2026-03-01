#!/bin/bash
set -euo pipefail

KIND_VERSION="v0.31.0"
FLUX_VERSION="v2.8.1"

# Install kind
curl -Lo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind

# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo VERSION="${FLUX_VERSION}" bash

# Create kind cluster or restore kubeconfig if it already exists
if kind get clusters | grep -q "^flux$"; then
  echo "Cluster 'flux' already exists, restoring kubeconfig"
  kind export kubeconfig --name flux
else
  kind create cluster --name flux --config .devcontainer/kind-cluster.yaml
  flux install
fi

# Verify tools
kubectl version --client
helm version
flux --version
