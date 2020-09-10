variable "vault_path" {
    description = "Vault path to use. If not set, vault is not used"
    type        = string
}

variable "index_templates" {
    description = "Custom index templates"
    type        = map(string)
    default     = {}
}

variable "ilm_policies" {
    description = "ILM policies"
    type        = map(string)
    default     = {}
}
