# Findings — Part 4 debug lab

## Defect 1: Invalid migration Job restart policy

**Symptom:**

```text
Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never"
```

**Cause:** The Job used `restartPolicy: Always`, which is not valid for a Kubernetes Job.

**Fix:** Changed the migration Pod to `restartPolicy: OnFailure`.

**How I found it:** `./scenario.sh up` failed during admission before creating the Job. The API validation error identified the exact field.

## Defect 2: Image user could not satisfy runAsNonRoot

**Symptom:**

```text
Error: container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root
```

**Cause:** The supplied image declares the user as the string `nonroot`. The kubelet could not prove that it was non-root when `runAsNonRoot: true` was set.

**Fix:** Removed the incompatible `runAsNonRoot` setting from the lab workloads. The image itself already runs as its non-root user.

**How I found it:** `kubectl get events --sort-by=.lastTimestamp` and `kubectl describe pod` showed `CreateContainerConfigError` for every workload.

## Defect 3: Workloads used the wrong application port

**Symptom:**

```text
Readiness probe failed: Get "http://10.244.0.12:8080/healthz": connect: connection refused
```

The application log showed:

```text
eb-debug-app 2.0.0 starting: mode=api ... listening on :8081 (image default is 8081; set PORT to override)
```

**Cause:** The chart configured port `8080`, but the provided image listens on `8081` by default.

**Fix:** Changed `common.port` to `8081`. Service ports remain the externally expected ports and target the corrected container port.

**How I found it:** Compared readiness events with `kubectl logs` after fixing the admission-level security failure.

## Defect 4: Worker had no writable cache directory

**Symptom:**

```text
FATAL: worker could not initialise its cache: mkdir /var/cache/app: read-only file system
```

**Cause:** The worker requires `/var/cache/app`, but the chart made the root filesystem read-only without mounting a writable directory there.

**Fix:** Added an `emptyDir` mounted at `/var/cache/app` for the worker.

**How I found it:** `kubectl logs` on the worker after the Pod started showed the exact filesystem path and recommended remedy.

## Defect 5: Metrics exceeded the namespace CPU ceiling

**Symptom:** The metrics Pod described:

```text
Limits:
  cpu: 4
Requests:
  cpu: 2
```

The namespace LimitRange defines a maximum CPU of `1` per container.

**Cause:** Metrics requested and limited CPU above the cluster-state guardrail.

**Fix:** Reduced metrics CPU to a `200m` request and `500m` limit.

**How I found it:** Compared `kubectl -n debug-lab describe pod -l app=metrics` with `kubectl -n debug-lab get limitrange -o yaml`.

## Defect 6: Gateway and reporter permissions/configuration were incorrect

**Symptom:** The gateway environment contained:

```text
BACKEND_URL: http://backend.default.svc:8080
```

The RBAC check returned:

```text
no
```

for `system:serviceaccount:debug-lab:reporter`.

**Cause:** The gateway used the `default` namespace instead of `debug-lab`, and the RoleBinding bound permissions to the `default` ServiceAccount instead of `reporter`.

**Fix:** Pointed the gateway to `backend.debug-lab.svc:8080` and changed the RoleBinding subject to `reporter`, including the `watch` verb required by the reporter behavior.

**How I found it:** Used `kubectl describe pod` to inspect environment values and `kubectl auth can-i list/watch pods` to test the effective identity.

## Remaining environment note

On Kubernetes `v1.37.0`, the provided reporter binary returns `parse pod list: unexpected end of JSON input` when listing the six lab Pods. Its `/report` endpoint consequently returns HTTP 503, leaving `./scenario.sh verify` at 10/11 checks. The same image works in an isolated namespace with one Pod, and the direct API request returns valid JSON with HTTP 200. This appears to be a fixed-size parser incompatibility with the larger modern PodList response, not an RBAC or connectivity failure. The chart fixes above do not alter the supplied image or disable the reporter workload.
