# wordpress

A Helm chart for [WordPress](https://wordpress.org) on the official
[`docker.io/library/wordpress`](https://hub.docker.com/_/wordpress) Apache image,
with an external MySQL/MariaDB.

## What this chart does

- **The core comes from the image, only `wp-content` is persistent.**
  `/var/www/html` is an emptyDir; an init container copies the WordPress core
  from the image into it on every pod start, and the image's entrypoint writes
  `wp-config.php` from environment variables. The image tag *is* the WordPress
  version - update WordPress by changing `image.tag`, then open `/wp-admin`
  once so it can upgrade the database. `WP_AUTO_UPDATE_CORE` is off, because a
  core update from the dashboard would only land in the emptyDir.
- `wp-content` (uploads, plugins, themes) is a PVC or an existing claim, with
  an optional `subPath` - e.g. `wordpress/wp-content` to reuse the volume of
  the Bitnami chart as is.
- Compliant with the `restricted` Pod Security Standard: any non-root uid
  (default 33 = www-data; use the uid that owns your existing `wp-content`),
  read-only root filesystem, no capabilities, Apache on port 8080.
- PHP limits, Apache `mpm_prefork` worker count, `WP_HOME`/`WP_SITEURL` and
  further `wp-config.php` lines from values.
- Optional OpenID Connect login via the
  [OpenID Connect Generic Client](https://wordpress.org/plugins/daggerhart-openid-connect-generic/)
  plugin, configured through `OIDC_*` constants. Endpoints are derived from a
  Keycloak realm URL unless set explicitly.
- Ingress, optional NetworkPolicy, `extraDeploy`.

Only the Apache image variants work (`*-apache`), not `fpm` or `alpine`.

## Install

```bash
helm install blog oci://ghcr.io/mithrandir1/helm-charts/wordpress \
  --set url=https://blog.example.com \
  --set database.host=mariadb.example.com:3306 \
  --set database.existingSecret=wordpress-db \
  --set secret.existingSecret=wordpress-secret \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=blog.example.com \
  --set ingress.hosts[0].paths[0].path=/
```

## Secrets

| Secret | Key | Purpose |
|---|---|---|
| `database.existingSecret` | `database.existingSecretPasswordKey` (default `WORDPRESS_DB_PASSWORD`) | Database password (`secretKeyRef`). Without `existingSecret` the chart renders one from `database.password`. |
| `secret.existingSecret` | `WORDPRESS_AUTH_KEY`, `WORDPRESS_SECURE_AUTH_KEY`, `WORDPRESS_LOGGED_IN_KEY`, `WORDPRESS_NONCE_KEY`, `WORDPRESS_AUTH_SALT`, `WORDPRESS_SECURE_AUTH_SALT`, `WORDPRESS_LOGGED_IN_SALT`, `WORDPRESS_NONCE_SALT` | Keys and salts. `wp-config.php` is regenerated on every start - without fixed values everybody is signed out on every restart. When migrating, copy them from the old `wp-config.php`. |
| `secret.existingSecret` | `OIDC_CLIENT_SECRET` | Client secret for `oidc.enabled`. |

Everything in `secret` is loaded via `envFrom`, so any other environment
variable of the image fits there too.

## OpenID Connect

The chart does not install plugins. Install and activate
`daggerhart-openid-connect-generic`, then set:

```yaml
oidc:
  enabled: true
  issuer: https://keycloak.example.com/realms/master
  clientId: blog
  linkExistingUsers: true      # match existing accounts by e-mail
  createIfDoesNotExist: false  # true = any IdP user gets an account
```

Redirect URI for the IdP client:
`<url>/wp-admin/admin-ajax.php?action=openid-connect-authorize`.

The plugin links accounts by e-mail and does **not** check `email_verified`:
only enable `linkExistingUsers` with an IdP where users cannot pick an
arbitrary unverified address (no open self-registration).

## Values

See [`values.yaml`](values.yaml) - every option is commented there and
validated by [`values.schema.json`](values.schema.json).
