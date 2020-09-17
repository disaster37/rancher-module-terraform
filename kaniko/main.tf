terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    rancher2   = ">= 1.8.3"
    vault      = ">= 2.11.0"
  }
}

locals {
    cluster_id        = data.rancher2_cluster.cluster.id
    project_id        = data.rancher2_project.project.id
    project_small_id  = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    namespace_id      = rancher2_namespace.namespace.id
    docker_server     = data.vault_generic_secret.vault.data["docker_server"]
    docker_username   = data.vault_generic_secret.vault.data["docker_username"]
    docker_password   = data.vault_generic_secret.vault.data["docker_password"]
    docker_email      = data.vault_generic_secret.vault.data["docker_email"]
    github_token      = data.vault_generic_secret.vault.data["github_token"]
    proxy             = data.vault_generic_secret.vault.data["proxy"]
    no_proxy          = data.vault_generic_secret.vault.data["no_proxy"]
    ca_crt            = data.vault_generic_secret.vault.data["ca_crt"]
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



resource "rancher2_registry" "registry" {
  name = "regcred"
  description = "Secret to connect on registry"
  project_id = local.project_id
  namespace_id = local.namespace_id
  registries {
    address  = local.docker_server
    username = local.docker_username
    password = local.docker_password
  }
}

resource "rancher2_secret" "github" {
  name = "github"
  description = "Secret to connect on github"
  project_id = local.project_id
  namespace_id = local.namespace_id
  data = {
    "GIT_USERNAME"    = base64encode(local.github_token)
  }
}

resource "rancher2_secret" "proxy" {
  name = "proxy"
  description = "Secret to connect on proxy"
  project_id = local.project_id
  namespace_id = local.namespace_id
  data = {
    "HTTP_PROXY"    = base64encode(local.proxy)
    "HTTPS_PROXY"   = base64encode(local.proxy)
    "http_proxy"    = base64encode(local.proxy)
    "https_proxy"   = base64encode(local.proxy)
    "no_proxy"      = base64encode(local.no_proxy)
    "NO_PROXY"      = base64encode(local.no_proxy)
  }
}

resource "rancher2_secret" "certificates" {
  name = "certificates"
  description = "Custom CA"
  project_id = local.project_id
  namespace_id = local.namespace_id
  data = {
    "ca-sihm.crt"    = base64encode(local.ca_crt)
  }
}