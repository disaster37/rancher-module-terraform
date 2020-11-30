terraform {
  required_version = ">= 0.12.0"

}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
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
  name       = "elastic"
  url        = "https://helm.elastic.co"
  scope      = "project"
  cluster_id = local.cluster_id
  project_id = local.project_id
  refresh    = true
  version    = "helm_v2"
}

