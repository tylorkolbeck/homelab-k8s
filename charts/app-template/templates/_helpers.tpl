{{/*
Base application name (defaults to .Release.Name)
*/}}
{{- define "app-template.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Deployment name (<app>-app)
*/}}
{{- define "app-template.deploymentName" -}}
{{- printf "%s-app" (include "app-template.name" .) -}}
{{- end -}}

{{/*
Service name (<app>-svc)
*/}}
{{- define "app-template.serviceName" -}}
{{- printf "%s-svc" (include "app-template.name" .) -}}
{{- end -}}

{{/*
Target namespace
*/}}
{{- define "app-template.namespace" -}}
{{- default .Values.global.appsNamespace .Values.namespace -}}
{{- end -}}

{{/*
Selector labels (matches existing <app>-app label convention)
*/}}
{{- define "app-template.selectorLabels" -}}
app: {{ include "app-template.deploymentName" . }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "app-template.labels" -}}
{{ include "app-template.selectorLabels" . }}
app.kubernetes.io/name: {{ include "app-template.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
