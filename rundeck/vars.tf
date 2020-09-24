variable "cluster_name" {
    description = "Cluster name where to deploy elastic"
    type        = string
}

variable "project_name" {
    description = "Project name where to deploy elastic"
    type        = string
}

variable "namespace" {
    description = "Namespace where to deploy elastic"
    type        = string
}

variable "catalog_name" {
    description = "Catalog name"
    type        = string
}

variable "template_name" {
    description = "Template name used to deploy elastic"
    default     = "elasticsearch"
    type        = string
}

variable "template_version" {
    description = "Template version used to deploy elastic"
    type        = string
}

variable "name" {
    description = "Application name"
    default     = "elasticsearch"
    type        = string
}

variable "description" {
    description = "Application description"
    default     = "Elasticsearch with all roles"
    type        = string
}

variable "values" {
    description = "Values contend used when invoke helm"
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

variable "vault_path" {
    description = "Vault path to use. If not set, vault is not used"
    type        = string
}

variable "pvcs" {
    description = "Additionnals PVC"
    type        = map(object({
        storage_class = string
        access_mode   = string
        size          = string
    }))
}

variable "credentials" {
    description = "List of credentials to retrive from vault to create on secrets"
    type        = list(string)
    default     = []
}