terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2 = ">= 1.8.3"
    vault    = ">= 2.11.0"
  }
}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
    project_small_id         = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    namespace_id             = rancher2_namespace.namespace.id
    credentials              = {for cred in var.credentials: upper(cred) => data.vault_generic_secret.vault.data[cred]}
    certificates             = {for cert in var.certificates: cert => data.vault_generic_secret.vault.data[cert]}
}

# Get data
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
  name                     = var.namespace
  project_id               = local.project_id
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

# Create secrets
resource "rancher2_secret" "credentials" {
    name = "${var.name}-credentials"
    description = "Credentials for Logstash"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data = {for k, v in local.credentials: k => base64encode(v)}
}
resource "rancher2_secret" "certificates" {
    name = "${var.name}-certificates"
    description = "Certificates for Logstash"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data = {for k, v in local.certificates: k => base64encode(v)}
}

# Create Elasticsearch with all roles
resource "rancher2_app" "app" {
    catalog_name     = "${local.project_small_id}:${var.catalog_name}"
    name             = var.name
    description      = var.description
    project_id       = local.project_id
    template_name    = var.template_name
    template_version = var.template_version
    target_namespace = var.namespace
    annotations      = var.annotations
    labels           = var.labels
    values_yaml      = base64encode(var.values)
    force_upgrade    = true
    
    depends_on = [rancher2_secret.credentials, rancher2_secret.certificates]
}