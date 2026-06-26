# namespaces

A Helm chart to deploy Kubernetes namespaces and their dependent resources, including NetworkPolicies, ResourceQuotas, LimitRanges, Vault secret integration, and RBAC RoleBindings.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.x
- Optional: [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso) or [External Secrets Operator](https://external-secrets.io/) for secret management

## Installing the Chart

```bash
helm install my-namespaces oci://ghcr.io/tloibl/helm-charts/namespaces --version 0.2.0 -f my-values.yaml
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.application_gitops_namespace` | Namespace where ArgoCD is deployed | `argocd` |
| `global.ingress_controller_range` | Comma-separated CIDR ranges for the ingress controller. If unset, a namespaceSelector with label `network.itdesign.at/policy-group: ingress` is used instead. | `""` |
| `global.tshirt_sizes` | List of predefined t-shirt size profiles for quotas and limit ranges | `[]` |

### Namespace Items (`namespaces[]`)

Each entry in the `namespaces` list can configure the following:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `name` | Name of the namespace (required) | — |
| `enabled` | Whether to create the namespace and its resources | `false` |
| `project_size` | Reference to a `global.tshirt_sizes[].name` to apply predefined quotas/limits | — |

#### Admin Group (`admin_group`)

Creates a RoleBinding granting admin access to a group or list of users.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `admin_group.enabled` | Enable RoleBinding creation | `false` |
| `admin_group.group_name` | External group name (e.g. LDAP/OIDC group) | — |
| `admin_group.users` | List of individual user names | `[]` |
| `admin_group.clusterrole` | ClusterRole to bind | `admin` |

#### Additional Settings (`additional_settings`)

Sets Pod Security Standards labels on the namespace.

| Parameter | Description | Values |
|-----------|-------------|--------|
| `additional_settings.podsecurity_audit` | Audit mode PSS level | `Privileged`, `Baseline`, `Restricted` |
| `additional_settings.podsecurity_warn` | Warn mode PSS level | `Privileged`, `Baseline`, `Restricted` |
| `additional_settings.podsecurity_enforce` | Enforce mode PSS level | `Privileged`, `Baseline`, `Restricted` |

#### Resource Quotas (`resourceQuotas`)

Ignored when `project_size` is set (t-shirt size quotas take precedence, but individual values override them).

| Parameter | Description |
|-----------|-------------|
| `resourceQuotas.enabled` | Enable ResourceQuota creation |
| `resourceQuotas.pods` | Max number of pods |
| `resourceQuotas.cpu` | Max CPU (e.g. `4`) |
| `resourceQuotas.memory` | Max memory (e.g. `4Gi`) |
| `resourceQuotas.ephemeral_storage` | Max ephemeral storage |
| `resourceQuotas.replicationcontrollers` | Max ReplicationControllers |
| `resourceQuotas.resourcequotas` | Max ResourceQuotas |
| `resourceQuotas.services` | Max Services |
| `resourceQuotas.secrets` | Max Secrets |
| `resourceQuotas.configmaps` | Max ConfigMaps |
| `resourceQuotas.persistentvolumeclaims` | Max PersistentVolumeClaims |
| `resourceQuotas.limits.cpu` | Max `limits.cpu` |
| `resourceQuotas.limits.memory` | Max `limits.memory` |
| `resourceQuotas.limits.ephemeral_storage` | Max `limits.ephemeral-storage` |
| `resourceQuotas.requests.cpu` | Max `requests.cpu` |
| `resourceQuotas.requests.memory` | Max `requests.memory` |
| `resourceQuotas.requests.storage` | Max `requests.storage` |
| `resourceQuotas.requests.ephemeral_storage` | Max `requests.ephemeral-storage` |
| `resourceQuotas.storageclasses` | Map of StorageClass-scoped quota keys to values |

> Note: lowercase `gi`/`mi` suffixes in memory/storage values are automatically converted to `Gi`/`Mi`.

#### Limit Ranges (`limitRanges`)

Ignored when `project_size` is set (t-shirt size limits take precedence, but individual values override them).

| Parameter | Description |
|-----------|-------------|
| `limitRanges.enabled` | Enable LimitRange creation |
| `limitRanges.pod.max.cpu` | Max CPU per pod |
| `limitRanges.pod.max.memory` | Max memory per pod |
| `limitRanges.pod.min.cpu` | Min CPU per pod |
| `limitRanges.pod.min.memory` | Min memory per pod |
| `limitRanges.container.max.cpu` | Max CPU per container |
| `limitRanges.container.max.memory` | Max memory per container |
| `limitRanges.container.min.cpu` | Min CPU per container |
| `limitRanges.container.min.memory` | Min memory per container |
| `limitRanges.container.default.cpu` | Default CPU limit per container |
| `limitRanges.container.default.memory` | Default memory limit per container |
| `limitRanges.container.defaultRequest.cpu` | Default CPU request per container |
| `limitRanges.container.defaultRequest.memory` | Default memory request per container |
| `limitRanges.pvc.min.storage` | Min storage per PVC |
| `limitRanges.pvc.max.storage` | Max storage per PVC |

#### Default Network Policies (`default_policies`)

Five NetworkPolicies are created automatically for every enabled namespace. Each can be disabled individually.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `default_policies.disable_allow_from_ingress` | Disable "allow from ingress controller" policy | `false` |
| `default_policies.disable_allow_from_monitoring` | Disable "allow from monitoring" policy | `false` |
| `default_policies.disable_allow_from_same_namespace` | Disable "allow intra-namespace" policy | `false` |
| `default_policies.disable_allow_kube_apiserver` | Disable "allow from kube-apiserver" policy | `false` |
| `default_policies.disable_deny_all_egress` | Disable "deny all egress" policy | `false` |

The ingress policy selects the ingress controller either by CIDR (`global.ingress_controller_range`) or by namespaceSelector label `network.itdesign.at/policy-group: ingress`. The monitoring policy selects by label `network.itdesign.at/policy-group: monitoring`.

#### Custom Network Policies (`networkpolicies[]`)

| Parameter | Description |
|-----------|-------------|
| `networkpolicies[].name` | Policy name (appended to namespace name) |
| `networkpolicies[].active` | Whether to create the policy |
| `networkpolicies[].podSelector` | PodSelector for the policy target |
| `networkpolicies[].ingressRules` | List of ingress rules with `selectors` and `ports` |
| `networkpolicies[].egressRules` | List of egress rules with `selectors` and `ports` |

#### Vault / External Secrets (`vaultSecrets`)

Supports both [Vault Secrets Operator (VSO)](https://developer.hashicorp.com/vault/docs/platform/k8s/vso) and [External Secrets Operator (ESO)](https://external-secrets.io/).

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vaultSecrets.operator` | Secret operator to use: `vso` or `eso` | `vso` |

**Authentications** — creates `VaultAuth` (VSO) or `SecretStore` (ESO) CRDs:

| Parameter | Description | Required for |
|-----------|-------------|-------------|
| `vaultSecrets.authentications[].name` | Resource name | Both |
| `vaultSecrets.authentications[].role` | Vault Kubernetes auth role | Both |
| `vaultSecrets.authentications[].mount` | Kubernetes auth mount path | Both |
| `vaultSecrets.authentications[].serviceAccount` | ServiceAccount name | Both (default: `default`) |
| `vaultSecrets.authentications[].vaultAddress` | Vault server URL | ESO only |
| `vaultSecrets.authentications[].kvVersion` | KV engine version (`v1`/`v2`) | ESO (default: `v2`) |
| `vaultSecrets.authentications[].namespace` | Vault Enterprise namespace | ESO (optional) |

**Secrets** — creates `VaultStaticSecret` (VSO) or `ExternalSecret` (ESO) CRDs:

| Parameter | Description | Required for |
|-----------|-------------|-------------|
| `vaultSecrets.secrets[].name` | Secret name | Both |
| `vaultSecrets.secrets[].auth` | Reference to authentication resource name | Both |
| `vaultSecrets.secrets[].mount` | KV engine mount path | Both |
| `vaultSecrets.secrets[].path` | Secret path within the KV mount | Both |
| `vaultSecrets.secrets[].secretType` | Kubernetes Secret type (e.g. `Opaque`) | Both (optional) |
| `vaultSecrets.secrets[].refreshAfter` | Sync interval (e.g. `24h`) | Both (default: `3600s`/`1h`) |
| `vaultSecrets.secrets[].type` | Vault KV version: `kv-v1` or `kv-v2` | VSO (default: `kv-v2`) |
| `vaultSecrets.secrets[].namespace` | Vault Enterprise namespace | VSO (optional) |
| `vaultSecrets.secrets[].transformation` | VSO transformation configuration | VSO (optional) |

#### Kubernetes Secrets (`secrets`)

| Parameter | Description |
|-----------|-------------|
| `secrets.opaque[]` | List of Opaque secrets. Each item requires `name` and `data` (key-value map, values are base64-encoded automatically). |
| `secrets.dockerconfig[]` | List of `kubernetes.io/dockerconfigjson` pull secrets. Each item requires `name`, `hostname`, and `auth` (base64-encoded `user:password`). |
| `secrets.tls[]` | List of TLS secrets. Each item requires `name`; optionally `cert`, `key`, `ca` (PEM strings, base64-encoded automatically). |

### T-Shirt Sizes (`global.tshirt_sizes[]`)

Define reusable size profiles that namespaces can reference via `project_size`. Individual quota/limitRange values on the namespace override the t-shirt size defaults.

```yaml
global:
  tshirt_sizes:
    - name: small
      quota:
        pods: 10
        cpu: "4"
        memory: 8Gi
      limitRanges:
        container:
          default:
            cpu: 500m
            memory: 512Mi
          defaultRequest:
            cpu: 100m
            memory: 128Mi
```

## Examples

### Minimal namespace

```yaml
global:
  application_gitops_namespace: argocd

namespaces:
  - name: my-app
    enabled: true
```

### Namespace with quotas and admin group

```yaml
global:
  application_gitops_namespace: argocd

namespaces:
  - name: my-app
    enabled: true
    admin_group:
      enabled: true
      group_name: my-app-admins
    additional_settings:
      podsecurity_enforce: restricted
    resourceQuotas:
      enabled: true
      cpu: "8"
      memory: 16Gi
      pods: 20
    limitRanges:
      enabled: true
      container:
        default:
          cpu: 500m
          memory: 512Mi
        defaultRequest:
          cpu: 100m
          memory: 128Mi
```

### Namespace with VSO secret integration

```yaml
namespaces:
  - name: my-app
    enabled: true
    vaultSecrets:
      operator: vso
      authentications:
        - name: my-app-auth
          role: my-app-role
          mount: kubernetes
          serviceAccount: default
      secrets:
        - name: my-app-db-creds
          auth: my-app-auth
          mount: kv
          path: my-app/db
          type: kv-v2
          secretType: Opaque
          refreshAfter: 1h
```

### Namespace with t-shirt sizing

```yaml
global:
  application_gitops_namespace: argocd
  tshirt_sizes:
    - name: medium
      quota:
        cpu: "8"
        memory: 16Gi
        pods: 30
      limitRanges:
        container:
          default:
            cpu: 500m
            memory: 512Mi

namespaces:
  - name: my-app
    enabled: true
    project_size: medium
```
