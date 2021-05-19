terraform {
  required_version = ">= 0.12.0"

}

locals {
    cluster_id               = data.rancher2_cluster.cluster.id
    project_id               = data.rancher2_project.project.id
    project_small_id         = element(regex(":(p-.*)$", data.rancher2_project.project.id), 0)
    namespace_id             = rancher2_namespace.namespace.id
    namespace_name           = rancher2_namespace.namespace.name
    elastic_password         = data.vault_generic_secret.vault.data["elastic_password"]
    elastic_url              = data.vault_generic_secret.vault.data["elastic_url"]
    ldap_user                = data.vault_generic_secret.vault.data["ldap_user"]
    ldap_password            = data.vault_generic_secret.vault.data["ldap_password"]
    monitoring_user          = data.vault_generic_secret.vault.data["monitoring_user"]
    monitoring_password      = data.vault_generic_secret.vault.data["monitoring_password"]
    kibana_password          = data.vault_generic_secret.vault.data["KIBANA_PASSWORD"]
    kibana_username          = data.vault_generic_secret.vault.data["KIBANA_USERNAME"]
    logstash_system_password = data.vault_generic_secret.vault.data["LOGSTASH_SYSTEM_PASSWORD"]
    proxy                    = data.vault_generic_secret.vault.data["proxy"]
    keystore                 = {for cred in var.keystore: cred => data.vault_generic_secret.vault.data[cred]}
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

# Create persistant volume claim for backup
resource "kubernetes_persistent_volume_claim" "backup" {
  count            = var.with_snapshot_pvc == true ? 1 : 0
  wait_until_bound = true
  metadata {
    name = "pvc-elasticsearch-snapshot"
    namespace = local.namespace_name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "nfs-client"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}


# Create kube role
resource "kubernetes_role" "role" {
  metadata {
    name      = "create-secret"
    namespace = local.namespace_name
  }
  
  rule {
    api_groups = [""]
    resources = ["secrets"]
    verbs = [
      "update",
      "create",
      "get",
      "list",
      "delete",
    ]
  }
}

# Create service account
resource "kubernetes_service_account" "service" {
  metadata {
    name      = "elasticsearch-job"
    namespace = local.namespace_name
  }
  automount_service_account_token = true
}

# Create role binding
resource "kubernetes_role_binding" "rb" {
  metadata {
    name      = "create-secret_elasticsearch-job"
    namespace = local.namespace_name
  }
  
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind     = "Role"
    name     = kubernetes_role.role.metadata.0.name
  }
  
  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.service.metadata.0.name
    namespace = local.namespace_name
  }
}
  
  
# Job to create certificates
resource "kubernetes_job" "job" {
  metadata {
    name      = "job-certificates"
    namespace = local.namespace_name
  }
  
  spec {
    backoff_limit = 4
    template {
      metadata {
        name = "elasticsearch-certificats"
      }
      spec {
        container {
          args    = list(file("script.sh"))
          command = [
            "/bin/sh",
            "-c",
          ]
          image   = "docker.elastic.co/elasticsearch/elasticsearch:7.7.1"
          name    = "elasticsearch-certificats"
          env {
            name = "https_proxy"
            value_from {
              secret_key_ref {
                name = rancher2_secret.credentials.name
                key  = "proxy"
              }
            }
          }
          resources {
            requests {
              cpu = "100m"
              memory = "128Mi"
            }
            limits {
              cpu = "100m"
              memory = "128Mi"
            }
            
          }
        }
        restart_policy       = "Never"
        service_account_name = "elasticsearch-job"
        automount_service_account_token = true
      }
    }
  }
  
  depends_on = [kubernetes_role_binding.rb]
}

# Create config map for patchmanagement
resource "kubernetes_config_map" "patchmanagement" {
  metadata {
    name      = "patchmanagement"
    namespace = local.namespace_name
  }

  data = {
    pre-job  = file("file/pre-job.sh")
    post-job = file("file/post-job.sh")
    secrets  = rancher2_secret.credentials.name
  }
}

# Create secrets
resource "rancher2_secret" "credentials" {
    name = "elasticsearch-credentials"
    description = "Credentials for Elastic cluster"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data = {
        ELASTIC_USERNAME                                                                     = base64encode("elastic")
        ELASTIC_PASSWORD                                                                     = base64encode(local.elastic_password)
        ELASTICSEARCH_LDAP_USER                                                              = base64encode(local.ldap_user)
        ELASTICSEARCH_MONITORING_USER                                                        = base64encode(local.monitoring_user)
        ELASTICSEARCH_MONITORING_PASSWORD                                                    = base64encode(local.monitoring_password)
        KIBANA_PASSWORD                                                                      = base64encode(local.kibana_password)
        KIBANA_USERNAME                                                                      = base64encode(local.kibana_username)
        LOGSTASH_SYSTEM_PASSWORD                                                             = base64encode(local.logstash_system_password)
        proxy                                                                                = base64encode(local.proxy)
        ELASTIC_URL                                                                          = base64encode(local.elastic_url)
    }
}

resource "rancher2_secret" "keystore" {
    count        = length(local.keystore) > 0 ? 1 : 0
    name         = "elasticsearch-keystore"
    description  = "Keystore"
    project_id   = local.project_id
    namespace_id = local.namespace_id
    data         = {for k, v in local.keystore: k => base64encode(v)}
}

# Create Elasticsearch with all roles
resource "rancher2_app" "elasticsearch" {
    for_each         = var.topology
    catalog_name     = "${local.project_small_id}:${var.catalog_name}"
    name             = each.key
    description      = each.value["description"]
    project_id       = local.project_id
    template_name    = var.template_name
    template_version = var.template_version
    target_namespace = local.namespace_name
    values_yaml      = each.value["values"]
    annotations      = var.annotations
    labels           = var.labels
    force_upgrade    = var.force_upgrade
    depends_on       = [rancher2_namespace.namespace, rancher2_secret.credentials, rancher2_secret.keystore, kubernetes_job.job]
}