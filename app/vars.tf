variable "cluster_name" {
    description = "Cluster name where to deploy"
    type        = string
}

variable "project_name" {
    description = "Project name where to deploy"
    type        = string
}

variable "namespace" {
    description = "Namespace where to deploy"
    type        = string
}

variable "catalog_name" {
    description = "Catalog name used to deploy"
    default     = ""
    type        = string
}

variable "template_name" {
    description = "Template name used to deploy"
    type        = string
}

variable "template_version" {
    description = "Template version used to deploy"
    type        = string
}

variable "name" {
    description = "Application name"
    type        = string
}

variable "description" {
    description = "Application description"
    type        = string
}

variable "values_path" {
    description = "Values path used when invoke helm"
    type        = string
}

variable "annotations" {
    description = "Annotations to add on application"
    default     = {}
    type        = map
}

variable "labels" {
    description = "Labels to add on application"
    default     = {}
    type        = map
}

variable "vault_path" {
    description = "Vault path to use."
    type        = string
    default     = ""
}

variable "vault_global_path" {
    description = "Vault path to use."
    type        = string
    default     = ""
}

variable "resource_quota" {
    description = "Quota for the namespace"
    type        = object({
        limit = object({
            limits_cpu       = string
            limits_memory    = string
            requests_storage = string
        })
    })
}

variable "container_resource_limit" {
    description = "Default resource limit for container"
    type        = object({
        limits_cpu      = string
        limits_memory   = string
        requests_cpu    = string
        requests_memory = string
    })
}

variable "certificates" {
    description = "List of certificates to retrive from vault"
    type        = map(object({
        cert_key = string
        key_key  = string
    }))
    default     = {}
}

variable "global_certificates" {
    description = "List of certificates to retrive from vault"
    type        = list(string)
    default     = []
}

variable "credentials" {
    description = "List of credentials to retrive from vault"
    type        = list(string)
    default     = []
}

variable "secret_files" {
    description = "List of secret files to retrive from vault"
    type        = list(string)
    default     = []
}

variable "catalog" {
    description = "Catalog to create"
    type = object({
        name    = string
        url     = string
        version = string
    })
    default     = null
}

variable "is_project_catalog" {
    description = "Use project catalog, or global catalog"
    type        = bool
    default     = false
}

variable "is_substitute_values" {
    description = "Subsitute variable on values.yaml from credentials secrets"
    type        = bool
    default     = false
}

variable "force_upgrade" {
    description = "Force helm upgrade"
    type        = bool
    default     = false
}