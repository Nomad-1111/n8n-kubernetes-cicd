# ============================================================================
# Helm Template Helpers
# ============================================================================
# This file contains reusable template functions (helpers) used throughout
# the Helm chart. Helpers provide consistent naming and labeling across
# all resources in the chart.
# ============================================================================

# ----------------------------------------------------------------------------
# n8n.name - Returns the chart name
# ----------------------------------------------------------------------------
# Used to generate consistent naming across resources.
# Returns: "n8n"
{{- define "n8n.name" -}}
{{ .Chart.Name }}
{{- end }}

# ----------------------------------------------------------------------------
# n8n.fullname - Returns the full release name
# ----------------------------------------------------------------------------
# Used to generate unique resource names when multiple releases exist.
# Returns: Release name if set, otherwise chart name.
# Example: If release name is "n8n-dev", returns "n8n-dev"
{{- define "n8n.fullname" -}}
{{- if .Release.Name }}
{{ .Release.Name }}
{{- else }}
{{ include "n8n.name" . }}
{{- end }}
{{- end }}

# ----------------------------------------------------------------------------
# n8n.labels - Returns standard Kubernetes labels
# ----------------------------------------------------------------------------
# Generates standard Kubernetes labels for resource organization and
# management. These labels follow Kubernetes best practices and enable:
# - Resource selection and filtering
# - Service discovery
# - Resource organization
# - Monitoring and logging integration
#
# Labels generated:
# - app.kubernetes.io/name: Chart name (e.g., "n8n")
# - app.kubernetes.io/instance: Release name (e.g., "n8n-dev")
# - app.kubernetes.io/part-of: Application group (always "n8n")
{{- define "n8n.labels" -}}
app.kubernetes.io/name: {{ include "n8n.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: n8n
{{- end }}
