variable "cluster_name" {
    description = "Cluster name where to create project"
    type        = string
}

variable "name" {
    description = "Project name"
    type        = string
}

variable "description" {
    description = "Description of the project"
    default     = ""
    type        = string
}

variable "pod_security_policy_template_id" {
    description = "The pod security policy template id to use"
    default     = ""
    type        = string
}

variable "annotations" {
    description = "The annotations to add on project"
    type        = map
    default     = {}
}

variable "labels" {
    description = "The labels to add on project"
    default     = {}
    type        = map
}

variable "wait_for_cluster" {
    description = "Wait cluster to be alive"
    default     = false
    type        = bool
}

variable "vault_path" {
    description = "Vault path to use. If not set, vault is not used"
    type        = string
    default     = "secret/pki"
}


variable "resource_quota" {
    description = "The resource quota specification"
    default     = null
    type        = object({
        project_limit = object({
            limits_cpu       = string
            limits_memory    = string
            requests_storage = string
        })
        namespace_default_limit = object({
            limits_cpu       = string
            limits_memory    = string
            requests_storage = string
        })
    })
}

variable "container_resource_limit" {
    description = "The container resource limit specification"
    default     = null
    type        = object({
        limits_cpu      = string
        limits_memory   = string
        requests_cpu    = string
        requests_memory = string
    })
}

variable "roles" {
    description = "The roles to affect on project"
    type        = map(object({
        template = string
        user_id     = string
        group_id    = string
    }))
    default     = {}
}