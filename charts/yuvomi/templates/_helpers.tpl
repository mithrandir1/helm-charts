{{/*
Expand the name of the chart.
*/}}
{{- define "yuvomi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "yuvomi.fullname" -}}
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
{{- define "yuvomi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "yuvomi.labels" -}}
helm.sh/chart: {{ include "yuvomi.chart" . }}
{{ include "yuvomi.selectorLabels" . }}
app.kubernetes.io/version: {{ (.Values.image.tag | default .Chart.AppVersion) | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "yuvomi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "yuvomi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the service account to use
*/}}
{{- define "yuvomi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "yuvomi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret to use (existing one wins), empty when there is none.
*/}}
{{- define "yuvomi.secretName" -}}
{{- if .Values.secret.existingSecret }}
{{- .Values.secret.existingSecret }}
{{- else if .Values.secret.create }}
{{- include "yuvomi.fullname" . }}
{{- end }}
{{- end }}

{{/*
PVC name for a persistence entry.
Usage: include "yuvomi.pvcName" (dict "name" "data" "context" .)
*/}}
{{- define "yuvomi.pvcName" -}}
{{- $vol := index .context.Values.persistence .name }}
{{- if $vol.existingClaim }}
{{- $vol.existingClaim }}
{{- else }}
{{- printf "%s-%s" (include "yuvomi.fullname" .context) .name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
OIDC redirect URI: explicit value or derived from baseUrl.
*/}}
{{- define "yuvomi.oidcRedirectUri" -}}
{{- if .Values.oidc.redirectUri }}
{{- .Values.oidc.redirectUri }}
{{- else if .Values.baseUrl }}
{{- printf "%s/api/v1/auth/oidc/callback" (trimSuffix "/" .Values.baseUrl) }}
{{- end }}
{{- end }}
