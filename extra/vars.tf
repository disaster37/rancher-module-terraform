variable "name" {
    description = "The name to prefix resources"
    type        = string
}

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

variable "custom_secret_files" {
    description = "List of custom secret files to retrive from vault"
    type        = map(object({
        keys        = list(string)
        description = string
        annotations = map(string)
        labels      = map(string)
    }))
    default     = {}
}

variable "configmaps" {
    description = "List of configmap to retrive from vault"
    type        = map(object({
        keys        = list(string)
        annotations = map(string)
        labels      = map(string)
    }))
    default     = {}
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


variable "registries" {
    description = "Registries"
    type        = map(object({
        address_key  = string
        username_key = string
        password_key = string
    }))
    default     = {}
}

variable "pvcs" {
    description = "Additionnals PVC"
    type        = map(object({
        storage_class = string
        access_mode   = string
        size          = string
    }))
    default     = {}
}