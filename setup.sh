#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME=demo
NAMESPACE=demo
IMAGE=demo-service:local

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --wait 120s
fi

kubectl label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

docker build -t "$IMAGE" "$ROOT_DIR/service"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install demo "$ROOT_DIR/chart" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository=demo-service \
  --set image.tag=local \
  --wait \
  --timeout 180s

kubectl -n "$NAMESPACE" rollout status deployment/demo-demo-service --timeout=180s
printf '\nSetup complete.\n'
printf 'Verify: kubectl -n %s get pods,svc,ingress\n' "$NAMESPACE"
