# bulwark-webmail

A Helm chart for [Bulwark Webmail](https://github.com/bulwarkmail/webmail) — a modern, self-hosted webmail suite built on Next.js and the JMAP protocol, designed for [Stalwart Mail Server](https://stalw.art). Provides mail, calendar, contacts, and file management in a single application.

## Features

- Next.js application serving on port 3000
- Compliant with the Kubernetes `restricted` Pod Security Standard out of the box (runs as UID 1001, read-only rootfs, dropped capabilities, seccomp RuntimeDefault)
- Four independently configurable PersistentVolumeClaims for application data
- ConfigMap for non-sensitive configuration; Secret for `SESSION_SECRET` and OAuth credentials
- Classic Kubernetes Ingress **and** Gateway API HTTPRoute — enable either or both
- Optional HPA (autoscaling/v2 with CPU and memory metrics)
- Optional PodDisruptionBudget
- Optional NetworkPolicy with configurable ingress and egress rules
- `extraDeploy` for arbitrary additional Kubernetes objects (rendered as templates)
- Full JSON Schema validation for all values

## Prerequisites

- Kubernetes 1.25+
- Helm 3.10+
- A running [Stalwart Mail Server](https://stalw.art) (or any other JMAP-compatible server)
- (Optional) Gateway API CRDs installed for HTTPRoute support

## Installing the Chart

From a local clone:

```bash
helm install my-webmail ./charts/bulwark-webmail \
  --set config.jmapServerUrl=https://mail.example.com/jmap \
  --set secret.sessionSecret=$(openssl rand -hex 32)
```

From OCI registry:

```bash
helm install my-webmail oci://ghcr.io/mithrandir1/charts/bulwark-webmail \
  --set config.jmapServerUrl=https://mail.example.com/jmap \
  --set secret.sessionSecret=$(openssl rand -hex 32)
```

## Upgrading

```bash
helm upgrade my-webmail ./charts/bulwark-webmail
```

## Uninstalling

```bash
helm uninstall my-webmail
```

> **Note:** PersistentVolumeClaims are **not** deleted automatically. Remove them manually if no longer needed:
>
> ```bash
> kubectl delete pvc my-webmail-settings my-webmail-admin my-webmail-admin-state
> ```

## Parameters

### Image

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Container image repository | `ghcr.io/bulwarkmail/webmail` |
| `image.tag` | Image tag | `1.7.4` |
| `image.digest` | Optional SHA256 digest for immutable pinning | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets (for private registries) | `[]` |

### General

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of pod replicas | `1` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full release name | `""` |
| `extraEnv` | Extra environment variables | `[]` |
| `extraVolumes` | Extra volumes | `[]` |
| `extraVolumeMounts` | Extra volume mounts | `[]` |
| `extraDeploy` | Extra Kubernetes objects (rendered as templates) | `[]` |

### Service Account

| Parameter | Description | Default |
|---|---|---|
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.name` | Name override (defaults to fullname) | `""` |
| `serviceAccount.annotations` | Annotations for the ServiceAccount | `{}` |

### Security

The chart defaults comply with the Kubernetes `restricted` Pod Security Standard (PSS). The image already runs as the `nextjs` user (UID 1001).

| Parameter | Description | Default |
|---|---|---|
| `podSecurityContext.runAsNonRoot` | Require non-root user | `true` |
| `podSecurityContext.runAsUser` | UID to run as | `1001` |
| `podSecurityContext.runAsGroup` | GID to run as | `1001` |
| `podSecurityContext.fsGroup` | fsGroup for volume ownership | `1001` |
| `podSecurityContext.seccompProfile.type` | Seccomp profile | `RuntimeDefault` |
| `securityContext.allowPrivilegeEscalation` | Prevent privilege escalation | `false` |
| `securityContext.capabilities.drop` | Dropped capabilities | `["ALL"]` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |
| `securityContext.runAsNonRoot` | Require non-root user | `true` |
| `securityContext.runAsUser` | UID to run as | `1001` |

`/tmp` and `/app/.next/cache` are always mounted as `emptyDir` volumes to satisfy runtime write requirements when `readOnlyRootFilesystem` is enabled.

### Application Configuration

These values are rendered into a ConfigMap and injected as environment variables.

| Parameter | Description | Default |
|---|---|---|
| `config.jmapServerUrl` | JMAP server endpoint (**required**) | `https://mail.example.com/jmap` |
| `config.appName` | Display name shown in the UI | `Bulwark Webmail` |
| `config.logLevel` | Log verbosity (`error`/`warn`/`info`/`debug`) | `info` |
| `config.oauthIssuerUrl` | OAuth2/OIDC issuer URL for SSO (optional) | `""` |
| `config.TZ` | Container timezone | `Europe/Vienna` |

### Secrets

Sensitive values are rendered into a Kubernetes Secret. Set `secret.create: false` and `secret.existingSecret` to manage the Secret externally (e.g. via Vault, Sealed Secrets, or ESO).

| Parameter | Description | Default |
|---|---|---|
| `secret.create` | Create a Secret from the values below | `true` |
| `secret.existingSecret` | Name of an existing Secret to use instead | `""` |
| `secret.sessionSecret` | `SESSION_SECRET` — 32+ char random string (**required**) | `""` |
| `secret.oauthClientId` | OAuth2/OIDC client ID (optional) | `""` |
| `secret.oauthClientSecret` | OAuth2/OIDC client secret (optional) | `""` |

Generate a suitable session secret:

```bash
openssl rand -hex 32
```

### Persistence

Each volume corresponds to a directory under `/app/data/`. All four can be independently enabled, sized, and backed by different storage classes or existing claims.

> **Note:** HPA with more than one replica requires a `ReadWriteMany` storage class, or all persistence volumes must be disabled.

| Parameter | Description | Default |
|---|---|---|
| `persistence.settings.enabled` | Persist user settings and preferences | `true` |
| `persistence.settings.size` | PVC size | `1Gi` |
| `persistence.settings.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.settings.storageClass` | Storage class (`"-"` sets `storageClassName: ""`) | `""` |
| `persistence.settings.existingClaim` | Use an existing PVC | `""` |
| `persistence.admin.enabled` | Persist admin config, policies, plugins, themes | `true` |
| `persistence.admin.size` | PVC size | `1Gi` |
| `persistence.admin.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.admin.storageClass` | Storage class | `""` |
| `persistence.admin.existingClaim` | Use an existing PVC | `""` |
| `persistence.adminState.enabled` | Persist runtime state and audit logs | `true` |
| `persistence.adminState.size` | PVC size | `1Gi` |
| `persistence.adminState.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.adminState.storageClass` | Storage class | `""` |
| `persistence.adminState.existingClaim` | Use an existing PVC | `""` |
| `persistence.telemetry.enabled` | Persist anonymous telemetry data | `false` |
| `persistence.telemetry.size` | PVC size | `1Gi` |
| `persistence.telemetry.accessModes` | PVC access modes | `[ReadWriteOnce]` |
| `persistence.telemetry.storageClass` | Storage class | `""` |
| `persistence.telemetry.existingClaim` | Use an existing PVC | `""` |

### Service

| Parameter | Description | Default |
|---|---|---|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `3000` |
| `service.annotations` | Service annotations | `{}` |

### Ingress

| Parameter | Description | Default |
|---|---|---|
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.className` | IngressClass name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress host rules | see `values.yaml` |
| `ingress.tls` | TLS configuration | `[]` |

### Gateway API

Requires [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) installed in the cluster.

| Parameter | Description | Default |
|---|---|---|
| `gateway.enabled` | Enable HTTPRoute | `false` |
| `gateway.annotations` | HTTPRoute annotations | `{}` |
| `gateway.parentRefs` | Gateway parent references | see `values.yaml` |
| `gateway.hostnames` | Hostnames for the HTTPRoute | `[webmail.example.com]` |

### Resources

| Parameter | Description | Default |
|---|---|---|
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |

### Probes

| Parameter | Description | Default |
|---|---|---|
| `livenessProbe` | Liveness probe config (httpGet `/api/health`) | see `values.yaml` |
| `readinessProbe` | Readiness probe config (httpGet `/api/health`) | see `values.yaml` |
| `startupProbe` | Startup probe config (httpGet `/api/health`) | see `values.yaml` |

Set any probe key to `{}` to disable it.

### Autoscaling (HPA)

> **Note:** HPA with `replicaCount > 1` requires a `ReadWriteMany` storage class or all persistence volumes disabled.

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
| `networkPolicy.ingressRules` | Ingress rules (port 3000 from all) | see `values.yaml` |
| `networkPolicy.egressRules` | Egress rules (DNS + HTTP/HTTPS) | see `values.yaml` |

### Scheduling

| Parameter | Description | Default |
|---|---|---|
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `topologySpreadConstraints` | Topology spread constraints | `[]` |

---

## Examples

### Minimal Production Deployment

```yaml
config:
  jmapServerUrl: https://mail.example.com/jmap

secret:
  sessionSecret: "<openssl rand -hex 32>"

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: webmail.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: webmail-tls
      hosts:
        - webmail.example.com
```

### Gateway API Exposure

```yaml
gateway:
  enabled: true
  parentRefs:
    - name: prod-gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - webmail.example.com
```

### High-Availability Deployment

```yaml
replicaCount: 2

persistence:
  settings:
    accessModes: [ReadWriteMany]
    storageClass: nfs-client
  admin:
    accessModes: [ReadWriteMany]
    storageClass: nfs-client
  adminState:
    accessModes: [ReadWriteMany]
    storageClass: nfs-client

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

podDisruptionBudget:
  enabled: true
  minAvailable: 1

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: bulwark-webmail

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
                  - bulwark-webmail
          topologyKey: kubernetes.io/hostname
```

### Private Registry

```yaml
image:
  repository: registry.example.com/mirror/bulwarkmail/webmail
  tag: "1.2.3"
  digest: "sha256:abc123..."

imagePullSecrets:
  - name: registry-credentials
```

### Externally Managed Secret (Vault / ESO / Sealed Secrets)

```yaml
secret:
  create: false
  existingSecret: bulwark-webmail-secret
```

The referenced Secret must contain the keys `SESSION_SECRET` and optionally `OAUTH_CLIENT_ID` / `OAUTH_CLIENT_SECRET`.

### Extra Objects (e.g. a PodMonitor for Prometheus)

```yaml
extraDeploy:
  - apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      name: "{{ .Release.Name }}-webmail"
      namespace: "{{ .Release.Namespace }}"
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/name: bulwark-webmail
      podMetricsEndpoints:
        - port: http
          path: /metrics
```

### Namespace with Restricted PSS

The chart is ready for namespaces enforcing the `restricted` Pod Security Standard:

```bash
kubectl label namespace webmail \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest
```

---

## Source Code

- [Bulwark Webmail upstream](https://github.com/bulwarkmail/webmail)
- [Helm chart source](https://github.com/mithrandir1/helm-charts)
