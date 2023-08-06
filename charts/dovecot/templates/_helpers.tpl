{{/*
Return the proper dovecot image name
*/}}
{{- define "dovecot.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "dovecot.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" .Values.volumePermissions.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "dovecot.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.volumePermissions.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "dovecot.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "dovecot.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "dovecot.validateValues" -}}
{{- $messages := list -}}
{{/*
{{- $messages := append $messages (include "dovecot.validateValues.foo" .) -}}
{{- $messages := append $messages (include "dovecot.validateValues.bar" .) -}}
*/}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Dovecot credential secret name
*/}}
{{- define "dovecot.secretName" -}}
{{- coalesce .Values.existingSecret (include "common.names.fullname" .) -}}
{{- end -}}

{{/*
Dovecot ldap username secret key
*/}}
{{- define "dovecot.ldapUsernameKey" -}}
{{- if .Values.existingSecret -}}
    {{- print .Values.existingSecretLDAPUsernamedKey -}}
{{- else -}}
    {{- print "ldap_dn" -}}
{{- end -}}
{{- end -}}

{{/*
Dovecot ldap password secret key
*/}}
{{- define "dovecot.ldapPasswordKey" -}}
{{- if .Values.existingSecret -}}
    {{- print .Values.existingSecretLDAPPasswordKey -}}
{{- else -}}
    {{- print "ldap_password" -}}
{{- end -}}
{{- end -}}

{{/*
Dovecot doveadm password secret key
*/}}
{{- define "dovecot.doveadmPasswordKey" -}}
{{- if .Values.existingSecret -}}
    {{- print .Values.existingSecretDOVEADMPasswordKey -}}
{{- else -}}
    {{- print "doveadm_password" -}}
{{- end -}}
{{- end -}}
