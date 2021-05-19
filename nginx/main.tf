terraform {
  required_version = ">= 0.12.0"
}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
    namespace_id             = data.rancher2_namespace.namespace.id
    nginx_ssl_cert           = data.vault_generic_secret.vault.data["nginx_ssl_cert"]
    nginx_ssl_key            = data.vault_generic_secret.vault.data["nginx_ssl_key"]
}

data "vault_generic_secret" "vault" {
  path = var.vault_path
}
data "rancher2_cluster" "cluster" {
    name = var.cluster_name
}
data "rancher2_project" "project" {
    cluster_id  = local.cluster_id
    name        = "System"
}
data "rancher2_namespace" "namespace" {
  name = "ingress-nginx"
  project_id = local.project_id
}



resource "rancher2_secret" "secret" {
  name = "ingress-default-cert"
  description = "Default cert for ingress"
  project_id = local.project_id
  namespace_id = local.namespace_id
  data = {
    "tls.crt" = base64encode(local.nginx_ssl_cert)
    "tls.key" = base64encode(local.nginx_ssl_key)
  }
}