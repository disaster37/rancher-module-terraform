variable "cluster_name" {
    description = "Cluster name where to deploy elastic"
    type        = string
}

variable "vault_path" {
    description = "Vault path to use. If not set, vault is not used"
    type        = string
}