variable "cluster_name" {
    description = "Cluster name where to deploy elastic"
    type        = string
}

variable "project_name" {
    description = "Project name where to deploy elastic"
    type        = string
}

variable "namespace" {
    description = "Namespace where to deploy elastic"
    type        = string
}


variable "name" {
    description = "Application name"
    default     = "elasticsearch"
    type        = string
}

variable "description" {
    description = "Application description"
    default     = "Elasticsearch with all roles"
    type        = string
}


variable "annotations" {
    description = "Annotations to add on application"
    default     = {}
    type        = map
}

variable "labels" {
    description = "Labels to add on application"
    default     = {}
    type        = map
}