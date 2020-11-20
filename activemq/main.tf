terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2 = ">= 1.8.3"
    vault    = ">= 2.11.0"
  }
}

locals {
    cluster_id       = data.rancher2_cluster.cluster.id
    project_id       = data.rancher2_project.project.id
    namespace_id     = rancher2_namespace.namespace.id
    project_small_id = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    credentials      = data.vault_generic_secret.vault.data["credentials.properties"]
    jetty_realm      = data.vault_generic_secret.vault.data["jetty-realm.properties"]
    users            = data.vault_generic_secret.vault.data["users.properties"]
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

# Create secrets
resource "rancher2_secret" "credentials" {
  name = "credentials"
  description  = "ActiveMQ credentials"
  project_id   = local.project_id
  namespace_id = local.namespace_id
  data = {
    "credentials.properties" = base64encode(local.credentials)
    "jetty-realm.properties" = base64encode(local.jetty_realm)
    "users.properties"       = base64encode(local.users)
  }
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
    
    depends_on = [rancher2_namespace.namespace, rancher2_secret.credentials]
}