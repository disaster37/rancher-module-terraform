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
    description = "Catalog name used to deploy elastic"
    default     = "hm"
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

variable "topology" {
    description = "Topologie to deploy"
    type        = map(object({
        description = string
        values      = string
    }))
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
    description = "Vault path to use. If not set, vault is not used"
    type        = string
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

variable "with_snapshot_pvc" {
    description = "Auto create PVC for snapshot"
    type        = bool
    default     = true
}

variable "force_upgrade" {
    description = "Force helm upgrade"
    type        = bool
    default     = false
}