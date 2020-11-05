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
    kibana_password          = data.vault_generic_secret.vault.data["kibana_password"]
    kibana_encryption_key    = data.vault_generic_secret.vault.data["kibana_encryption_key"]
    certificates             = { for name, cert in var.certificates: name => {
                                 certs = data.vault_generic_secret.vault.data[cert.certs]
                                 key   = data.vault_generic_secret.vault.data[cert.key]
                                }}
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
    name = "kibana-credentials"
    description = "Credentials for Elastic cluster"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data = {
        ELASTICSEARCH_USERNAME            = base64encode("kibana")
        ELASTICSEARCH_PASSWORD            = base64encode(local.kibana_password)
        KIBANA_ENCRYPTION_KEY             = base64encode(local.kibana_encryption_key)
    }
}



resource "rancher2_certificate" "certificates" {
    for_each = local.certificates
    name = "certificate-${each.key}"
    description = "Certificates for Kibana"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    certs = base64encode(each.value["certs"])
    key   = base64encode(each.value["key"])
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
    
    depends_on = [rancher2_secret.credentials]
}