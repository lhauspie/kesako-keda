variable "project_id" {
  description = "Project ID"
}

variable "region" {
  description = "GCP Region"
}

variable "zone" {
  description = "GCP Zone"
}

variable "office_namespace" {
  description = "The Kubernetes Namespace for The Office Restaurant"
  default     = "restaurant"
}

variable "worker_name" {
  description = "The name of the docker image"
  default     = "worker"
}
variable "worker_image_version" {
  description = "The version of the docker image"
  default     = "1.1.0"
}
variable "worker_deployment_version" {
  description = "The version of the deployment in k8s"
  default     = "1-1-0"
}


variable "monitoring_namespace" {
  description = "The Kubernetes Namespace for Monitoring"
  default     = "monitoring"
}

variable "grafana_name" {
  description = "The name of the Grafana to be deployed"
  default = "grafana"
}
