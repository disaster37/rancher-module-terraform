terraform {
  required_version = ">= 0.13.0"

}

locals {
    cluster_id        = data.rancher2_cluster.cluster.id
    project_id        = data.rancher2_project.project.id
    namespace_id     = rancher2_namespace.namespace.id
    project_small_id  = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    secrets           = {
      proxy = data.vault_generic_secret.vault.data["proxy"]
    }
    certificate_crt   = data.vault_generic_secret.vault.data["cert_crt"]
    certificate_key   = data.vault_generic_secret.vault.data["cert_key"]
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

# Create secrets
resource "rancher2_certificate" "certificate" {
  certs        = base64encode(local.certificate_crt)
  key          = base64encode(local.certificate_key)
  name         = "che-tls"
  description  = "Certificate for CHE"
  project_id   = local.project_id
  namespace_id = local.namespace_id
}

resource "rancher2_secret" "ca" {
  name = "self-signed-certificate"
  description  = "CA"
  project_id   = local.project_id
  namespace_id = local.namespace_id
  annotations = {
      "che.eclipse.org/automount-workspace-secret" = "true"
      "che.eclipse.org/mount-as"                   = "file"
      "che.eclipse.org/mount-path"                 = "/usr/share/pki/ca-trust-source/anchors"
  }
  labels = {
      "app.kubernetes.io/component" = "workspace-secret"
      "app.kubernetes.io/part-of" = "che.eclipse.org"
  }
  data = {
    "ca.crt" = base64encode(local.ca_crt)
  }
}

# Create catalog
resource "rancher2_catalog" "catalog" {
  name       = "che"
  url        = "https://harbor.rancher-prd.hm.dm.ad/chartrepo/che"
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
    
    depends_on = [rancher2_catalog.catalog, rancher2_namespace.namespace, rancher2_certificate.certificate, rancher2_secret.ca]
}