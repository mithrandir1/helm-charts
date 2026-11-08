# yuvomi

A Helm chart for [Yuvomi](https://yuvomi.cloud), a self-hosted family planner
(calendar, tasks, meals, shopping, budget, documents). Upstream ships only a
Docker image ([`ghcr.io/ulsklyc/yuvomi`](https://github.com/ulsklyc/yuvomi)),
no chart.

## What this chart does

- One Deployment, 0 or 1 replicas, `Recreate` strategy. Yuvomi keeps all data
  in a single SQLite/SQLCipher file, so it cannot scale horizontally; the
  schema rejects `replicaCount > 1` and there is no HPA or PDB.
- Compliant with the `restricted` Pod Security Standard: runs as the image's
  `node` user (uid 1000), read-only root filesystem, `/tmp` as emptyDir.
- PVCs for `data` (database) and `backups` (the app's own scheduled backups),
  optional PVCs for `modules` and local `documents` storage.
- Non-secret settings go into a ConfigMap, secrets into a Secret (created by
  the chart or an existing one, e.g. from External Secrets) - both via `envFrom`,
  so any variable from upstream's
  [`.env.example`](https://github.com/ulsklyc/yuvomi/blob/main/.env.example)
  can be set through `env` or `secret.values`.
- Ingress or Gateway API HTTPRoute, optional NetworkPolicy, `extraDeploy`.

## Install

```bash
helm install yuvomi oci://ghcr.io/mithrandir1/helm-charts/yuvomi \
  --set baseUrl=https://yuvomi.example.com \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=yuvomi.example.com \
  --set ingress.hosts[0].paths[0].path=/
```

Then open `https://yuvomi.example.com/setup` and create the first administrator.

## Secrets

| Key | Purpose |
|---|---|
| `SESSION_SECRET` | Cookie signing key. Changing it signs everybody out once. |
| `DB_ENCRYPTION_KEY` | SQLCipher key. **Can never change** once the database is encrypted. |
| `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` | OIDC client, see below. |
| `EMAIL_SMTP_USER`, `EMAIL_SMTP_PASS` | SMTP, if configured via `env.EMAIL_SMTP_*`. |

Generate both keys with `openssl rand -hex 32`. If neither is supplied, a fresh
installation generates them on the first start and stores them under
`<data>/.secrets/` - on the same volume as the database, so a backup of that
volume alone is enough to restore, but also enough to decrypt. Supplying
`DB_ENCRYPTION_KEY` from a secret store keeps key and data apart.

Set `DB_ENCRYPTION_KEY` **before** the first start. An existing unencrypted
database is encrypted on the next start once a key appears; a database that is
already encrypted refuses to start with a different key.

## OIDC

```yaml
baseUrl: https://yuvomi.example.com
oidc:
  enabled: true
  issuer: https://keycloak.example.com/realms/master
  allowSignup: false        # only link accounts the admin created
  allowPasswordLogin: true  # set false once an admin is linked to the IdP
secret:
  existingSecret: yuvomi-secret   # with OIDC_CLIENT_ID / OIDC_CLIENT_SECRET
```

Redirect URI to register at the provider: `<baseUrl>/api/v1/auth/oidc/callback`.

Yuvomi links an SSO login to an existing account by e-mail only when the
provider sends `email_verified: true`.

## Values

See [values.yaml](values.yaml) - every option is commented there.
