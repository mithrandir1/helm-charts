# py-kms

A Helm chart for [py-kms](https://github.com/py-kms-organization/py-kms) — a KMS activation server for Microsoft products with an optional web-based management GUI.

## Features

- KMS activation server on port 1688
- Web-based management GUI on port 8080
- SQLite persistence via PersistentVolumeClaim
- Compliant with the Kubernetes `restricted` Pod Security Standard out of the box
- Optional Ingress, HPA, PodDisruptionBudget, and NetworkPolicy
- Full values schema validation

## Installing the Chart

```bash
helm install my-kms oci://ghcr.io/your-org/charts/py-kms
```

Or from a local clone:

```bash
helm install my-kms ./charts/py-kms
```

## Upgrading

```bash
helm upgrade my-kms ./charts/py-kms
```

## Uninstalling

```bash
helm uninstall my-kms
```

Note: The PersistentVolumeClaim is **not** deleted automatically. Remove it manually if no longer needed:

```bash
kubectl delete pvc my-kms-database
```

## Parameters

### Image

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Container image repository | `ghcr.io/py-kms-organization/py-kms` |
| `image.tag` | Image tag (digest pinned by default) | `python3@sha256:…` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### General

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of replicas | `1` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full release name | `""` |
| `TZ` | Container timezone | `Europe/Vienna` |
| `extraEnv` | Extra environment variables | `[]` |
| `extraVolumes` | Extra volumes | `[]` |
| `extraVolumeMounts` | Extra volume mounts | `[]` |

### Service Account

| Parameter | Description | Default |
|---|---|---|
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.name` | Name override (defaults to fullname) | `""` |
| `serviceAccount.annotations` | Annotations for the ServiceAccount | `{}` |

### Security

The chart defaults comply with the Kubernetes `restricted` Pod Security Standard (PSS).

| Parameter | Description | Default |
|---|---|---|
| `podSecurityContext.runAsNonRoot` | Require non-root user | `true` |
| `podSecurityContext.runAsUser` | UID to run as | `1000` |
| `podSecurityContext.runAsGroup` | GID to run as | `1000` |
| `podSecurityContext.fsGroup` | fsGroup for volume ownership | `1000` |
| `podSecurityContext.seccompProfile.type` | Seccomp profile | `RuntimeDefault` |
| `securityContext.allowPrivilegeEscalation` | Prevent privilege escalation | `false` |
| `securityContext.capabilities.drop` | Dropped capabilities | `["ALL"]` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |
| `securityContext.runAsNonRoot` | Require non-root user | `true` |
| `securityContext.runAsUser` | UID to run as | `1000` |

A `/tmp` emptyDir volume is always mounted to satisfy Python's temporary file requirements when `readOnlyRootFilesystem` is enabled.

### Persistence

| Parameter | Description | Default |
|---|---|---|
| `persistence.enabled` | Enable SQLite persistence | `true` |
| `persistence.size` | PVC size | `1Gi` |
| `persistence.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.storageClass` | Storage class (`"-"` disables class field) | `""` |
| `persistence.existingClaim` | Use an existing PVC instead of creating one | `""` |

### Services

| Parameter | Description | Default |
|---|---|---|
| `service.kms.type` | KMS service type | `ClusterIP` |
| `service.kms.port` | KMS service port | `1688` |
| `service.kms.nodePort` | NodePort value (only when type is NodePort) | `31688` |
| `service.kms.annotations` | KMS service annotations | `{}` |
| `service.gui.type` | GUI service type | `ClusterIP` |
| `service.gui.port` | GUI service port | `8080` |
| `service.gui.annotations` | GUI service annotations | `{}` |

### Ingress

| Parameter | Description | Default |
|---|---|---|
| `ingress.enabled` | Enable Ingress for the GUI | `false` |
| `ingress.className` | IngressClass name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress host rules | see `values.yaml` |
| `ingress.tls` | TLS configuration | `[]` |

### Resources

| Parameter | Description | Default |
|---|---|---|
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `256Mi` |

### Probes

| Parameter | Description | Default |
|---|---|---|
| `livenessProbe` | Liveness probe config (tcpSocket on kms port) | see `values.yaml` |
| `readinessProbe` | Readiness probe config (httpGet on GUI port) | see `values.yaml` |
| `startupProbe` | Startup probe config (tcpSocket on kms port) | see `values.yaml` |

Set any probe key to `{}` or `null` to disable it.

### Autoscaling (HPA)

> **Note:** HPA requires a `ReadWriteMany` storage class (or `persistence.enabled: false`) when scaling above one replica.

| Parameter | Description | Default |
|---|---|---|
| `autoscaling.enabled` | Enable HorizontalPodAutoscaler | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `3` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | _(unset)_ |

### Pod Disruption Budget

| Parameter | Description | Default |
|---|---|---|
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `false` |
| `podDisruptionBudget.minAvailable` | Minimum available pods | `1` |
| `podDisruptionBudget.maxUnavailable` | Maximum unavailable pods | _(unset)_ |

### Network Policy

| Parameter | Description | Default |
|---|---|---|
| `networkPolicy.enabled` | Enable NetworkPolicy | `false` |
| `networkPolicy.ingressRules` | Ingress rules (ports 1688 + 8080 from all) | see `values.yaml` |
| `networkPolicy.egressRules` | Egress rules (DNS only) | see `values.yaml` |

### Scheduling

| Parameter | Description | Default |
|---|---|---|
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `topologySpreadConstraints` | Topology spread constraints | `[]` |

## High-Availability Example

For a resilient, multi-replica deployment spread across nodes:

```yaml
replicaCount: 2

persistence:
  enabled: true
  accessModes:
    - ReadWriteMany
  storageClass: nfs-client

podDisruptionBudget:
  enabled: true
  minAvailable: 1

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: py-kms

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - py-kms
          topologyKey: kubernetes.io/hostname
```

## Ingress Example

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: kms.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: kms-tls
      hosts:
        - kms.example.com
```

## Existing PVC Example

```yaml
persistence:
  enabled: true
  existingClaim: my-existing-kms-pvc
```

## Namespace with Restricted PSS

The chart is ready for namespaces enforcing the `restricted` Pod Security Standard:

```bash
kubectl label namespace kms \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest
```

## Source Code

- [py-kms upstream](https://github.com/py-kms-organization/py-kms)
- [Helm chart source](https://github.com/your-org/helm-charts)
