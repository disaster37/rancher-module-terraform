variable "vault_path" {
    description = "Vault path to use. If not set, vault is not used"
    type        = string
    default     = ""
}

variable "ilm_policies" {
    description = "ILM policies"
    type        = map(string)
    default     = {}
}

variable "credentials" {
    description = "List of credentials to retrive from vault"
    type        = list(string)
    default     = []
}

variable "roles" {
    description = "Elasticsearch roles"
    type        = map(object({
        cluster = list(string)
        indices = object({
            names      = list(string)
            privileges = list(string)         
        })
    }))
    default = {}
}

variable "users" {
    description = "Elasticsearch local users"
    type        = list(object({
        user_key     = string
        password_key = string
        roles        = list(string)
    }))
    default = []
}

variable "roles_mapping" {
    description = "Roles mapping"
    type        = map(object({
        roles = list(string)
        rules = string
    }))
    default = {}
}

variable "license_key" {
    description = "The license key"
    type        = string
    default     = ""
}

variable "index_template" {
    description = "The index templates"
    type        = map(string)
    default     = {}
}

variable "index_component_template" {
    description = "The index component templates"
    type        = map(string)
    default     = {}
}

variable "snapshots_repository" {
    description = "The snapshot repositories"
    type        = map(object({
        type     = string
        settings = map(string)
    }))
    default = {}
}

variable "slm_policies" {
    description = "The slm policies"
    type        = map(object({
        name       = string
        schedule  = string
        repository = string
        settings   = string
        retention  = string
    }))
    default = {}
}

variable "user_spaces" {
    description = "Users spaces on Kibana"
    type        = map(object({
        description = string
        disabled_features    = list(string)    
    }))
    default = {}
}

variable "kibana_roles" {
    description = "Kibana roles"
    type        = map(object({
        kibana  = list(object({
            base     = list(string)
            spaces   = list(string)
            features = map(list(string))
        }))     
    }))
    default = {}
}

variable "kibana_objects" {
    description = "Kibana objects"
    type        = map(object({
        data           = string
        space          = string
        deep_reference = bool
        export_objects = list(object({
            id   = string
            type = string
        }))
    }))
    default = {}
}