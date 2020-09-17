terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2 = ">= 1.8.3"
    vault    = ">= 2.11.0"
  }
}

locals {
    cluster_id        = data.rancher2_cluster.cluster.id
    project_id        = data.rancher2_project.project.id
    project_small_id  = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    ca_certs          = data.vault_generic_secret.vault.data["ca_certs"]
    ldap_user         = data.vault_generic_secret.vault.data["ldap_user"]
    ldap_password     = data.vault_generic_secret.vault.data["ldap_password"]
    github_token      = data.vault_generic_secret.vault.data["github_token"]
    proxy             = data.vault_generic_secret.vault.data["proxy"]
    credentials       = {for cred in var.credentials: cred => data.vault_generic_secret.vault.data[cred]}
}

data "vault_generic_secret" "vault" {
  path = var.vault_path
}

data "rancher2_cluster" "cluster" {
    name = var.cluster_name
}
data "rancher2_project" "project" {
    cluster_id  = local.cluster_id
    name        = var.project_name
}


# Create namespace
resource "rancher2_namespace" "namespace" {
  name = var.namespace
  project_id = local.project_id
  labels                   = {
    "field.cattle.io/projectId" = local.project_small_id
  }
  
  dynamic "container_resource_limit" {
      for_each = var.container_resource_limit[*]
      content {
          limits_cpu      = container_resource_limit.value["limits_cpu"]
          limits_memory   = container_resource_limit.value["limits_memory"]
          requests_cpu    = container_resource_limit.value["requests_cpu"]
          requests_memory = container_resource_limit.value["requests_memory"]
      }
  }
    
    
  dynamic "resource_quota" {
      for_each = var.resource_quota[*]
      content {
          dynamic "limit" {
              for_each = resource_quota.value.limit[*]
              content {
                  limits_cpu       = limit.value["limits_cpu"]
                  limits_memory    = limit.value["limits_memory"]
                  requests_storage = limit.value["requests_storage"]
              }
          }
      }
  }
}

resource "rancher2_secret" "secret" {
  name         = "rundeck-secret"
  project_id   = local.project_id
  namespace_id = rancher2_namespace.namespace.id
  data         = {
    "RUNDECK_JAAS_LDAP_BINDDN"         = base64encode(local.ldap_user)
    "RUNDECK_JAAS_LDAP_BINDPASSWORD"   = base64encode(local.ldap_password)
    "GITHUB_TOKEN"                     = base64encode(local.github_token)
    "proxy"                            = base64encode(local.proxy)
  }
}

resource "rancher2_secret" "certificates" {
  name         = "rundeck-certificate"
  project_id   = local.project_id
  namespace_id = rancher2_namespace.namespace.id
  data         = {
    "pki_hm.crt"                     = base64encode(local.ca_certs)
  }
}

resource "rancher2_secret" "credentials" {
    name = "rundeck-credentials"
    description = "Credentials for rundecks"
    project_id   = local.project_id
    namespace_id = rancher2_namespace.namespace.id
    data = {for k, v in local.credentials: k => base64encode(v)}
}

# Create persistant volume claim
resource "kubernetes_persistent_volume_claim" "pvc" {
  wait_until_bound = true
  for_each = var.pvcs
  metadata {
    name = each.key
    namespace = var.namespace
  }
  spec {
    access_modes = [each.value.access_mode]
    storage_class_name = each.value.storage_class
    resources {
      requests = {
        storage = each.value.size
      }
    }
  }

  depends_on = [rancher2_namespace.namespace]
}

# Create app
resource "rancher2_app" "app" {
    catalog_name     = var.catalog_name
    name             = var.name
    description      = var.description
    project_id       = local.project_id
    template_name    = var.template_name
    template_version = var.template_version
    target_namespace = var.namespace
    annotations      = var.annotations
    labels           = var.labels
    values_yaml      = base64encode(var.values)
    
    depends_on = [rancher2_namespace.namespace]
}