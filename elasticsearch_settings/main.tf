terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    elasticsearch = ">= 7.0.0"
    kibana = ">= 7.0.0"
    vault    = ">= 2.11.0"
  }
}

locals {
    logstash_user            = data.vault_generic_secret.vault.data["logstash_user"]
    logstash_password        = data.vault_generic_secret.vault.data["logstash_password"]
    elasticsearch_license    = data.vault_generic_secret.vault.data["elasticsearch_license"]
}

# Get data
data "vault_generic_secret" "vault" {
  path = var.vault_path
}