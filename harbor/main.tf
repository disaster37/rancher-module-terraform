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
    secrets           = {
      proxy             = data.vault_generic_secret.vault.data["proxy"]
      admin_password    = data.vault_generic_secret.vault.data["admin_password"]
      secret_key        = data.vault_generic_secret.vault.data["secret_key"]
      registry_user     = data.vault_generic_secret.vault.data["registry_user"]
      registry_password = data.vault_generic_secret.vault.data["registry_password"]
      registry_htpasswd = "${data.vault_generic_secret.vault.data["registry_user"]}:${bcrypt(data.vault_generic_secret.vault.data["registry_password"], 10)}"
      db_password       = data.vault_generic_secret.vault.data["db_password"]
    }
    
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

# Create catalog
resource "rancher2_catalog" "catalog" {
  name       = "harbor"
  url        = "https://helm.goharbor.io"
  scope      = "project"
  cluster_id = local.cluster_id
  project_id = local.project_id
  refresh    = true
  version    = "helm_v3"
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
  name         = "harbor-tls"
  project_id   = local.project_id
  namespace_id = rancher2_namespace.namespace.id
  data         = {}
}


# Create app
resource "rancher2_app" "app" {
    catalog_name     = "${local.project_small_id}:${rancher2_catalog.catalog.name}"
    name             = var.name
    description      = var.description
    project_id       = local.project_id
    template_name    = var.template_name
    template_version = var.template_version
    target_namespace = var.namespace
    annotations      = var.annotations
    labels           = var.labels
    values_yaml      = base64encode(templatefile(var.values_path, local.secrets))
    
    depends_on = [rancher2_catalog.catalog, rancher2_namespace.namespace]
}