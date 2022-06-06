{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
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
This allows us to not have image: .Values.xxxx.ssss/.Values.xxx.xxx:.Values.ssss
in every single template.
*/}}
{{- define "broker.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $imageName := .Values.image.repository -}}
{{- $tag := .Values.image.tag -}}
{{- printf "%s/%s:%s" $registryName $imageName $tag -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "broker.postgresql.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "postgresql" "chartValues" .Values.postgresql "context" $) -}}
{{- end -}}

{{/*
Return the Database hostname
*/}}
{{- define "broker.databaseHost" -}}
{{- if eq .Values.postgresql.architecture "replication" }}
{{- ternary (include "broker.postgresql.fullname" .) .Values.externalDatabase.config.host .Values.postgresql.enabled -}}-primary
{{- else -}}
{{- ternary (include "broker.postgresql.fullname" .) .Values.externalDatabase.config.host .Values.postgresql.enabled -}}
{{- end -}}
{{- end -}}

{{/*
Return the Database port
*/}}
{{- define "broker.databasePort" -}}
{{- ternary "5432" .Values.externalDatabase.config.port .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Return the databaseAdapter configured
*/}}
{{- define "broker.databaseAdapter" -}}
{{- ternary "postgres" .Values.externalDatabase.config.adapter .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Return the database name
*/}}
{{- define "broker.databaseName" -}}
{{- ternary .Values.postgresql.auth.database .Values.externalDatabase.config.databaseName .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Return the Database username
*/}}
{{- define "broker.databaseUser" -}}
{{- ternary .Values.postgresql.auth.username .Values.externalDatabase.config.auth.user .Values.postgresql.enabled | quote -}}
{{- end -}}


{{/*
Return the Database Secret Name
*/}}
{{- define "broker.databaseSecretName" -}}
{{- if .Values.postgresql.enabled }}
    {{- if .Values.postgresql.auth.existingSecret }}
        {{- tpl .Values.postgresql.auth.existingSecret $ -}}
    {{- else -}}
        {{- default (include "broker.postgresql.fullname" .) (tpl .Values.postgresql.auth.existingSecret $) -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.externalDatabase.enabled }}
        {{- .Values.externalDatabase.config.auth.existingSecret -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the databaseSecret key to retrieve credentials for database
*/}}
{{- define "broker.databaseSecretKey" -}}
{{- if .Values.postgresql.enabled -}}
    {{- if .Values.postgresql.auth.existingSecret -}}
        {{- .Values.postgresql.auth.secretKeys.userPasswordKey  -}}
    {{- else -}}
        {{- print "password" -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.externalDatabase.enabled }}
        {{- if .Values.externalDatabase.config.auth.existingSecret -}}
            {{- .Values.externalDatabase.config.auth.existingSecretPasswordKey -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

