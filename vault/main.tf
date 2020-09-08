terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2 = ">= 1.8.3"
  }
}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
    namespace_id             = rancher2_namespace.namespace.id
    project_small_id         = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    aws_access_key_id        = data.vault_generic_secret.vault.data["aws_access_key_id"]
    aws_kms_seal_key_id      = data.vault_generic_secret.vault.data["aws_kms_seal_key_id"]
    aws_region               = data.vault_generic_secret.vault.data["aws_region"]
    aws_secret_access_key    = data.vault_generic_secret.vault.data["aws_secret_access_key"]
    proxy                    = data.vault_generic_secret.vault.data["proxy"]  
}

data "rancher2_cluster" "cluster" {
    name = var.cluster_name
}
data "rancher2_project" "project" {
    cluster_id  = local.cluster_id
    name        = var.project_name
}
data "vault_generic_secret" "vault" {
  path = var.vault_path
}

# Create catalog
resource "rancher2_catalog" "catalog" {
  name       = "hashicorp"
  url        = "https://helm.releases.hashicorp.com"
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

# Secrets
resource "rancher2_secret" "credentials" {
  name = "vault-credentials"
  description = "Secrets for vault"
  project_id = local.project_id
  namespace_id = local.namespace_id
  data = {
    "proxy"                    = base64encode(local.proxy)
    "AWS_ACCESS_KEY_ID"        = base64encode(local.aws_access_key_id)
    "AWS_SECRET_ACCESS_KEY"    = base64encode(local.aws_secret_access_key)
    "AWS_REGION"               = base64encode(local.aws_region)
    "VAULT_AWSKMS_SEAL_KEY_ID" = base64encode(local.aws_kms_seal_key_id)
  }
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
    values_yaml      = base64encode(var.values)
    
    depends_on = [rancher2_catalog.catalog, rancher2_namespace.namespace]
}