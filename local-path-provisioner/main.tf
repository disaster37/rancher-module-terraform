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
    project_small_id         = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
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
  name       = "local-path-provisioner"
  url        = "https://github.com/rancher/local-path-provisioner"
  scope      = "project"
  cluster_id = local.cluster_id
  project_id = local.project_id
  refresh    = true
  version    = "helm_v3"
  branch     = "master"
}

# Create namespace
resource "rancher2_namespace" "namespace" {
  name = var.namespace
  project_id = local.project_id
  
  container_resource_limit {
    limits_cpu = "100m"
    limits_memory = "128Mi"
    requests_cpu = "1m"
    requests_memory = "1Mi"
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