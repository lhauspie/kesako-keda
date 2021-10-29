provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

#data "google_client_config" "client_cfg" {}
#
#provider "kubernetes" {
#  host                   = "https://${google_container_cluster.primary.endpoint}"
#  token                  = data.google_client_config.client_cfg.access_token
#  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
#}
