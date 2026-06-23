{{/*
Expand the name of the chart.
*/}}
{{- define "bulwark-webmail.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bulwark-webmail.fullname" -}}
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
{{- define "bulwark-webmail.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bulwark-webmail.labels" -}}
helm.sh/chart: {{ include "bulwark-webmail.chart" . }}
{{ include "bulwark-webmail.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bulwark-webmail.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bulwark-webmail.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bulwark-webmail.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bulwark-webmail.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the name of the Secret to use.
Uses an existing secret when provided, otherwise derives the name from the release.
*/}}
{{- define "bulwark-webmail.secretName" -}}
{{- if .Values.secret.existingSecret }}
{{- .Values.secret.existingSecret }}
{{- else }}
{{- include "bulwark-webmail.fullname" . }}
{{- end }}
{{- end }}

{{/*
Return the PVC name for a given persistence volume.
Usage: include "bulwark-webmail.pvcName" (dict "volume" "settings" "volumeKey" "settings" "context" .)
The "volume" value is the key in .Values.persistence (e.g. "settings", "admin", "adminState", "telemetry").
The "volumeKey" is the kebab-case name used in the PVC name (e.g. "admin-state").
*/}}
{{- define "bulwark-webmail.pvcName" -}}
{{- $ctx := .context }}
{{- $vol := index $ctx.Values.persistence .volume }}
{{- if $vol.existingClaim }}
{{- $vol.existingClaim }}
{{- else }}
{{- printf "%s-%s" $ctx.Release.Name .volumeKey | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
