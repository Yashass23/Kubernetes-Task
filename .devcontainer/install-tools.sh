#!/usr/bin/env bash
set -euo pipefail

echo "Installing kubectl..."

KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"

curl -L \
  -o /tmp/kubectl \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

echo "Installing Helm..."

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
sudo chmod 0755 /usr/local/bin/helm

echo "Installing Kind..."

KIND_VERSION="$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | \
  grep '"tag_name":' | \
  head -1 | \
  cut -d '"' -f4)"

curl -Lo /tmp/kind \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"

sudo install -m 0755 /tmp/kind /usr/local/bin/kind

echo "Installing useful utilities..."

sudo apt-get update
sudo apt-get install -y jq shellcheck

echo
echo "Installed versions:"
echo "-------------------"

docker --version
kubectl version --client
helm version --short
kind version
jq --version
shellcheck --version | head -1

echo
echo "Environment ready."