{{/*
Expand the name of the chart.
*/}}
{{- define "{{APP_NAME}}.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "{{APP_NAME}}.fullname" -}}
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
{{- define "{{APP_NAME}}.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "{{APP_NAME}}.labels" -}}
helm.sh/chart: {{ include "{{APP_NAME}}.chart" . }}
{{ include "{{APP_NAME}}.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "{{APP_NAME}}.selectorLabels" -}}
app.kubernetes.io/name: {{ include "{{APP_NAME}}.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service-specific labels (example for {{SERVICE_NAME}})
Duplicate this pattern for each service, replacing {{SERVICE_NAME}} with actual service names.
*/}}
{{- define "{{APP_NAME}}.{{SERVICE_NAME}}.labels" -}}
{{ include "{{APP_NAME}}.labels" . }}
app.kubernetes.io/component: {{SERVICE_NAME}}
{{- end }}

{{/*
Service-specific selector labels (example for {{SERVICE_NAME}})
*/}}
{{- define "{{APP_NAME}}.{{SERVICE_NAME}}.selectorLabels" -}}
{{ include "{{APP_NAME}}.selectorLabels" . }}
app.kubernetes.io/component: {{SERVICE_NAME}}
{{- end }}

{{/*
ServiceAccount name for {{SERVICE_NAME}}
*/}}
{{- define "{{APP_NAME}}.{{SERVICE_NAME}}.serviceAccountName" -}}
{{- printf "%s-{{SERVICE_NAME}}" (include "{{APP_NAME}}.fullname" .) }}
{{- end }}

{{/*
Add more service-specific helpers following the pattern above.
Example for service2:

{{- define "{{APP_NAME}}.service2.labels" -}}
{{ include "{{APP_NAME}}.labels" . }}
app.kubernetes.io/component: service2
{{- end }}

{{- define "{{APP_NAME}}.service2.selectorLabels" -}}
{{ include "{{APP_NAME}}.selectorLabels" . }}
app.kubernetes.io/component: service2
{{- end }}

{{- define "{{APP_NAME}}.service2.serviceAccountName" -}}
{{- printf "%s-service2" (include "{{APP_NAME}}.fullname" .) }}
{{- end }}
*/}}
