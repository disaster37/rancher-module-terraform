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

variable "repo_name" {
    description = "Helm repository name"
    default     = ""
    type        = string
}

variable "chart_name" {
    description = "Chart name used to deploy"
    type        = string
}

variable "chart_version" {
    description = "Chart version used to deploy"
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

variable "disable_open_api_validation" {
    description = "Disable open api validation when deploy with helm"
    type        = bool
    default     = false
}

variable "network_policy_allow_from_all_namespace" {
    description = "Allow to connect form all namespace in cluster"
    type        = bool
    default     = false
}