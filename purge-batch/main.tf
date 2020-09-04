terraform {
  required_version = ">= 0.12.0"

  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_providers {
    kubernetes = ">= 1.11.3"
  }
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



# Create batch job to purge (temporary)
resource "kubernetes_cron_job" "job1" {
  metadata {
    name      = "purge-audit-ran37hpd1"
    namespace = rancher2_namespace.namespace.name
  }
  
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 1
    schedule                      = "* * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 0
    suspend                       = false
    
    
    job_template {
      metadata {}
      spec {
        parallelism   = 1
        backoff_limit = 2
        ttl_seconds_after_finished    = 10
        template {
          metadata {
            name = "purge-audit-log"
          }
          spec {
            node_selector = {
              "kubernetes.io/hostname" = "ran37hpd1.hm.dm.ad"
            }
            container {
              name    = "shell"
              image   = "alpine:latest"
              command = ["/bin/sh"]
              args    = [
                "-c",
                "rm -rf /mnt/audit-log/audit-log-*"
              ]
              volume_mount {
                  name = "audit-log"
                  mount_path = "/mnt/audit-log"
              }
            }
            volume {
                name = "audit-log"
                host_path {
                  path = "/var/log/kube-audit"
                  type = "DirectoryOrCreate"
                }
            }
            toleration {
              key = "master"
              operator = "Exists"
              effect = "NoSchedule"
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job" "job2" {
  metadata {
    name      = "purge-audit-ran37hpd2"
    namespace = rancher2_namespace.namespace.name
  }
  
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "* * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 5
    suspend                       = false
    
    
    job_template {
      metadata {}
      spec {
        parallelism   = 1
        backoff_limit = 2
        ttl_seconds_after_finished    = 10
        template {
          metadata {
            name = "purge-audit-log"
          }
          spec {
            node_selector = {
              "kubernetes.io/hostname" = "ran37hpd2.hm.dm.ad"
            }
            container {
              name    = "shell"
              image   = "alpine:latest"
              command = ["/bin/sh"]
              args    = [
                "-c",
                "rm -rf /mnt/audit-log/audit-log-*"
              ]
              volume_mount {
                  name = "audit-log"
                  mount_path = "/mnt/audit-log"
              }
            }
            volume {
                name = "audit-log"
                host_path {
                  path = "/var/log/kube-audit"
                  type = "DirectoryOrCreate"
                }
            }
            toleration {
              key = "master"
              operator = "Exists"
              effect = "NoSchedule"
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job" "job3" {
  metadata {
    name      = "purge-audit-ran37hpd3"
    namespace = rancher2_namespace.namespace.name
  }
  
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "* * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 5
    suspend                       = false
    
    
    job_template {
      metadata {}
      spec {
        parallelism   = 1
        backoff_limit = 2
        ttl_seconds_after_finished    = 10
        template {
          metadata {
            name = "purge-audit-log"
          }
          spec {
            node_selector = {
              "kubernetes.io/hostname" = "ran37hpd3.hm.dm.ad"
            }
            container {
              name    = "shell"
              image   = "alpine:latest"
              command = ["/bin/sh"]
              args    = [
                "-c",
                "rm -rf /mnt/audit-log/audit-log-*"
              ]
              volume_mount {
                  name = "audit-log"
                  mount_path = "/mnt/audit-log"
              }
            }
            volume {
                name = "audit-log"
                host_path {
                  path = "/var/log/kube-audit"
                  type = "DirectoryOrCreate"
                }
            }
            toleration {
              key = "master"
              operator = "Exists"
              effect = "NoSchedule"
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}