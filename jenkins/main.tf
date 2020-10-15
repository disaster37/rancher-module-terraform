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
    user             = data.vault_generic_secret.vault.data["user"]
    password         = data.vault_generic_secret.vault.data["password"]
    ldap_user        = data.vault_generic_secret.vault.data["ldap_user"]
    ldap_password    = data.vault_generic_secret.vault.data["ldap_password"]
    proxy            = data.vault_generic_secret.vault.data["proxy"]
    no_proxy         = data.vault_generic_secret.vault.data["no_proxy"]
    docker_server    = data.vault_generic_secret.vault.data["docker_server"]
    docker_username  = data.vault_generic_secret.vault.data["docker_username"]
    docker_password  = data.vault_generic_secret.vault.data["docker_password"]
    secrets           = {
        proxy_user = data.vault_generic_secret.vault.data["proxy_user"]
        proxy_password =  data.vault_generic_secret.vault.data["proxy_password"]
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

# Create secrets
resource "rancher2_secret" "credentials" {
  name = "credentials"
  description  = "Credentials for jenkins"
  project_id   = local.project_id
  namespace_id = local.namespace_id
  data = {
    "jenkins-admin-user"     = base64encode(local.user)
    "jenkins-admin-password" = base64encode(local.password)
    "LDAP_USER"              = base64encode(local.ldap_user)
    "LDAP_PASSWORD"          = base64encode(local.ldap_password)
  }
}

resource "rancher2_secret" "env" {
  name = "env"
  description  = "env for jenkins"
  project_id   = local.project_id
  namespace_id = local.namespace_id
  data = {
    "http_proxy"  = base64encode(local.proxy)
    "https_proxy" = base64encode(local.proxy)
    "no_proxy"    = base64encode(local.no_proxy)
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

# Create catalog
resource "rancher2_catalog" "catalog" {
  name       = "jenkins"
  url        = "https://charts.jenkins.io"
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
    
    depends_on = [rancher2_catalog.catalog, rancher2_namespace.namespace, rancher2_secret.credentials, rancher2_secret.env, rancher2_registry.registry]
}