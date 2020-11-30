terraform {
  required_version = ">= 0.12.0"

}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
    project_small_id         = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    namespace_id             = rancher2_namespace.namespace.id
    credentials              = {for cred in var.credentials: upper(cred) => data.vault_generic_secret.vault[0].data[cred]}
    secret_files             = {for cred in var.secret_files: cred => data.vault_generic_secret.vault[0].data[cred]}
    certificates             = {for cert, value in var.certificates: cert => {
                                    cert = data.vault_generic_secret.vault[0].data[value.cert_key]
                                    key  = data.vault_generic_secret.vault[0].data[value.key_key]
                                }}
    registries               = {for reg, value in var.registries: reg => {
                                    address  = data.vault_generic_secret.vault[0].data[value.address_key]
                                    username = data.vault_generic_secret.vault[0].data[value.username_key]
                                    password = data.vault_generic_secret.vault[0].data[value.password_key]
                                }}
    catalog_name             = var.catalog == null ? var.is_project_catalog == true ? "${local.project_small_id}:${var.catalog_name}" : var.catalog_name : "${local.project_small_id}:${rancher2_catalog.catalog[0].name}"
    values                   = var.is_substitute_values == true ? templatefile(var.values_path, local.credentials) : file(var.values_path)
}

# Get data
data "vault_generic_secret" "vault" {
    count = var.vault_path == "" ? 0 : 1
    path = var.vault_path
}
data "vault_generic_secret" "vault_global" {
    count = var.vault_global_path == "" ? 0 : 1
    path = var.vault_global_path
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
    count        = length(local.credentials) > 0 ? 1 : 0
    name         = "${var.name}-credentials"
    description  = "Credentials"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data         = {for k, v in local.credentials: k => base64encode(v)}
}
resource "rancher2_certificate" "certificates" {
    for_each     = local.certificates
    name         = "${each.key}-certificates"
    description  = "Certificates"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    certs        = base64encode(each.value.cert)
    key          = base64encode(each.value.key)
}
resource "rancher2_secret" "secret_files" {
    count        = length(local.secret_files) > 0 ? 1 : 0
    name         = "${var.name}-secrets"
    description  = "Secret files"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data         = {for k, v in local.secret_files: k => base64encode(v)}
}
resource "rancher2_registry" "registry" {
    for_each = local.registries
    name = each.key
    description = "Secret to connect on registry"
    project_id = local.project_id
    namespace_id = local.namespace_id
    registries {
        address  = each.value.address
        username = each.value.username
        password = each.value.password
    }
}

# Create catalog
resource "rancher2_catalog" "catalog" {
  count      = var.catalog == null ? 0 : 1
  name       = var.catalog.name
  url        = var.catalog.url
  scope      = "project"
  cluster_id = local.cluster_id
  project_id = local.project_id
  refresh    = true
  version    = var.catalog.version
}

# Create Elasticsearch with all roles
resource "rancher2_app" "app" {
    catalog_name     = local.catalog_name
    name             = var.name
    description      = var.description
    project_id       = local.project_id
    template_name    = var.template_name
    template_version = var.template_version
    target_namespace = var.namespace
    annotations      = var.annotations
    labels           = var.labels
    values_yaml      = base64encode(local.values)
    force_upgrade    = var.force_upgrade

    depends_on = [rancher2_namespace.namespace]
}