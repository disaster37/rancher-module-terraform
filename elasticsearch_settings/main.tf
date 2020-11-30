terraform {
  required_version = ">= 0.12.0"

}

locals {  
    users       = {for user in var.users:  data.vault_generic_secret.vault[0].data[user.user_key] => {
        password = data.vault_generic_secret.vault[0].data[user.password_key]
        roles    = user.roles
    }}
    license     = data.vault_generic_secret.vault[0].data[var.license_key]
}

# Get data
data "vault_generic_secret" "vault" {
    count = var.vault_path == "" ? 0 : 1
    path = var.vault_path
}

