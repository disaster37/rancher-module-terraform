terraform {
  required_version = ">= 0.12.17"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2 = ">= 1.8.3"
    vault    = ">= 2.11.0"
  }
}

locals {
    cluster_id      = data.rancher2_cluster.cluster.id
    ca_certs        = data.vault_generic_secret.vault.data["ca_certs"]
}

# Get data
data "rancher2_cluster" "cluster" {
    name = var.cluster_name
}

data "vault_generic_secret" "vault" {
  path = var.vault_path
}

# Create project
resource "rancher2_project" "project" {
    name                            = var.name
    cluster_id                      = local.cluster_id
    description                     = var.description
    pod_security_policy_template_id = var.pod_security_policy_template_id
    annotations                     = var.annotations
    labels                          = var.labels
    wait_for_cluster                = var.wait_for_cluster
    
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
            dynamic "project_limit" {
                for_each = resource_quota.value.project_limit[*]
                content {
                    limits_cpu       = project_limit.value["limits_cpu"]
                    limits_memory    = project_limit.value["limits_memory"]
                    requests_storage = project_limit.value["requests_storage"]
                }
            }
            
            dynamic "namespace_default_limit" {
                for_each = resource_quota.value.namespace_default_limit[*]
                content {
                    limits_cpu       = namespace_default_limit.value["limits_cpu"]
                    limits_memory    = namespace_default_limit.value["limits_memory"]
                    requests_storage = namespace_default_limit.value["requests_storage"]
                }
            }
            
        }
    }
}

# Create secrets
resource "rancher2_secret" "pki" {
  name = "pki"
  description  = "CA certificats"
  project_id   = rancher2_project.project.id
  data = {
    "ca_hm.crt"  = base64encode(local.ca_certs)
  }
}