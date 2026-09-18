# Kubernetes DevOps Take-Home

This repository contains the service, Helm chart, one-command kind setup, and the Part 4 debugging lab.

## Run It

Requirements: Docker, kind, kubectl, and Helm.

```bash
./setup.sh
kubectl -n demo get pods,svc,ingress
kubectl -n demo port-forward service/demo-demo-service 8080:80
curl http://127.0.0.1:8080/
curl -i http://127.0.0.1:8080/healthz
```

The setup script is safe to run repeatedly. For an Ingress check, add `127.0.0.1 demo.local` to `/etc/hosts`, then run `curl -H 'Host: demo.local' http://127.0.0.1/` when the kind ingress ports are available.

## Chart Checks

```bash
helm lint ./chart
helm template demo ./chart --set replicaCount=3 --set config.appName=interview --set config.version=9.2.1
```

## Resource Choices

The default request is 50m CPU and 64Mi memory, with limits of 200m CPU and 128Mi memory. The service is small and mostly idle, so the request is enough for scheduling without reserving excessive capacity. The limit allows short bursts while bounding resource use. These are starting points to validate with production measurements, not universal capacity guarantees.

## Part 4 Lab

```bash
cd lab
script -q part4-session.log
./scenario.sh up
./scenario.sh verify
# investigate and fix lab/broken-chart/
./scenario.sh verify
exit
```

The lab chart is fixed from observed cluster behavior. `cluster-state/` remains unchanged.

## Deliberate Gaps and Production Work

This exercise does not include persistent storage, external secret management, TLS certificate automation, network policies, autoscaling, PodDisruptionBudgets, or a production image registry. Those omissions reduce scope but leave security, availability, and operational risks. Production work would add signed and scanned images, pinned digests, CI/CD gates, TLS and secret rotation, network policies, autoscaling based on measurements, disruption budgets, centralized logs and metrics, alerting, backups where state exists, and a staged deployment strategy.

## How I Used AI

I used GitHub Copilot to help interpret the assignment, inspect the Helm templates, generate an initial service and chart scaffold, and reason about diagnostic commands. I verified the generated work with Docker builds, Helm lint/render checks, and real Kubernetes behavior. I retained the lab fixes and findings only after reproducing them on my own kind cluster and corrected assumptions when cluster output disagreed with static inspection.