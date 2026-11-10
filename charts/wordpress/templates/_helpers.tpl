{{/*
Expand the name of the chart.
*/}}
{{- define "wordpress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "wordpress.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wordpress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Image tag: explicit value or "<appVersion>-php8.3-apache".
*/}}
{{- define "wordpress.imageTag" -}}
{{- .Values.image.tag | default (printf "%s-php8.3-apache" .Chart.AppVersion) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wordpress.labels" -}}
helm.sh/chart: {{ include "wordpress.chart" . }}
{{ include "wordpress.selectorLabels" . }}
app.kubernetes.io/version: {{ include "wordpress.imageTag" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wordpress.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wordpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the service account to use
*/}}
{{- define "wordpress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wordpress.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the env Secret to use (existing one wins), empty when there is none.
*/}}
{{- define "wordpress.secretName" -}}
{{- if .Values.secret.existingSecret }}
{{- .Values.secret.existingSecret }}
{{- else if .Values.secret.create }}
{{- include "wordpress.fullname" . }}
{{- end }}
{{- end }}

{{/*
Secret holding the database password.
*/}}
{{- define "wordpress.dbSecretName" -}}
{{- .Values.database.existingSecret | default (printf "%s-db" (include "wordpress.fullname" .)) }}
{{- end }}

{{/*
PVC name for wp-content.
*/}}
{{- define "wordpress.pvcName" -}}
{{- .Values.persistence.existingClaim | default (printf "%s-wp-content" (include "wordpress.fullname" .) | trunc 63 | trimSuffix "-") }}
{{- end }}

{{/*
Host part of .Values.url (used as Apache ServerName).
*/}}
{{- define "wordpress.host" -}}
{{- if .Values.url }}
{{- (urlParse .Values.url).host }}
{{- else }}
{{- "localhost" }}
{{- end }}
{{- end }}

{{/*
OIDC endpoint: explicit value or Keycloak layout below the issuer.
Usage: include "wordpress.oidcEndpoint" (dict "name" "token" "path" "token" "context" .)
*/}}
{{- define "wordpress.oidcEndpoint" -}}
{{- $explicit := index .context.Values.oidc.endpoints .name }}
{{- if $explicit }}
{{- $explicit }}
{{- else }}
{{- printf "%s/protocol/openid-connect/%s" (trimSuffix "/" .context.Values.oidc.issuer) .path }}
{{- end }}
{{- end }}

{{/*
PHP code for WORDPRESS_CONFIG_EXTRA. Values are passed through squote, which
yields a valid single-quoted PHP string as long as they contain no quote or
backslash - the schema keeps URLs and IDs in that range.
*/}}
{{- define "wordpress.configExtra" -}}
{{- with .Values.url }}
define('WP_HOME', {{ trimSuffix "/" . | squote }});
define('WP_SITEURL', {{ trimSuffix "/" . | squote }});
{{- end }}
{{- with .Values.config.fsMethod }}
define('FS_METHOD', {{ . | squote }});
{{- end }}
{{- if .Values.config.disableCoreAutoUpdate }}
define('WP_AUTO_UPDATE_CORE', false);
{{- end }}
{{- if .Values.oidc.enabled }}
define('OIDC_LOGIN_TYPE', {{ .Values.oidc.loginType | squote }});
define('OIDC_CLIENT_ID', {{ .Values.oidc.clientId | squote }});
define('OIDC_CLIENT_SECRET', getenv_docker('OIDC_CLIENT_SECRET', ''));
define('OIDC_CLIENT_SCOPE', {{ .Values.oidc.scope | squote }});
define('OIDC_ISSUER', {{ trimSuffix "/" .Values.oidc.issuer | squote }});
define('OIDC_ENDPOINT_LOGIN_URL', {{ include "wordpress.oidcEndpoint" (dict "name" "login" "path" "auth" "context" .) | squote }});
define('OIDC_ENDPOINT_TOKEN_URL', {{ include "wordpress.oidcEndpoint" (dict "name" "token" "path" "token" "context" .) | squote }});
define('OIDC_ENDPOINT_USERINFO_URL', {{ include "wordpress.oidcEndpoint" (dict "name" "userinfo" "path" "userinfo" "context" .) | squote }});
define('OIDC_ENDPOINT_LOGOUT_URL', {{ include "wordpress.oidcEndpoint" (dict "name" "logout" "path" "logout" "context" .) | squote }});
define('OIDC_ENDPOINT_JWKS_URL', {{ include "wordpress.oidcEndpoint" (dict "name" "jwks" "path" "certs" "context" .) | squote }});
define('OIDC_LINK_EXISTING_USERS', {{ ternary 1 0 .Values.oidc.linkExistingUsers }});
define('OIDC_CREATE_IF_DOES_NOT_EXIST', {{ ternary 1 0 .Values.oidc.createIfDoesNotExist }});
define('OIDC_REDIRECT_USER_BACK', {{ ternary 1 0 .Values.oidc.redirectUserBack }});
define('OIDC_REDIRECT_ON_LOGOUT', {{ ternary 1 0 .Values.oidc.redirectOnLogout }});
define('OIDC_ENFORCE_PRIVACY', {{ ternary 1 0 .Values.oidc.enforcePrivacy }});
define('OIDC_ENABLE_LOGGING', {{ ternary 1 0 .Values.oidc.enableLogging }});
{{- end }}
{{- with .Values.config.extra }}
{{ . }}
{{- end }}
{{- end }}
