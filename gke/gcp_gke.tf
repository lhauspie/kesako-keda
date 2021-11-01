variable "gke_machine_type" {
  description = "Type of Virtual Machine for GKE nodes"
}
variable "gke_num_nodes" {
  description = "Number of gke nodes per zone"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.zone
  
  network    = google_compute_network.network.name
  subnetwork = google_compute_subnetwork.subnet.name

  #  # We can't create a cluster with no node pool defined, but we want to only use
  #  # separately managed node pools. So we create the smallest possible default
  #  # node pool and immediately delete it.
  #  initial_node_count       = 1
  #  remove_default_node_pool = true

  node_pool {
    name       = "${var.project_id}-gke"
#    location   = var.zone
#    cluster    = google_container_cluster.primary.name
    node_count = var.gke_num_nodes

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]

      labels = {
        env = var.project_id
      }

      machine_type = var.gke_machine_type
      preemptible  = true
      tags         = ["gke-node", "${var.project_id}-gke"]
      metadata = {
        disable-legacy-endpoints = "true"
      }
    }
  }
}

# Separately Managed Node Pool
#resource "google_container_node_pool" "primary_nodes" {
#  name       = "${google_container_cluster.primary.name}-node-pool"
#  location   = var.zone
#  cluster    = google_container_cluster.primary.name
#  node_count = var.gke_num_nodes
#
#  node_config {
#    oauth_scopes = [
#      "https://www.googleapis.com/auth/logging.write",
#      "https://www.googleapis.com/auth/monitoring",
#    ]
#
#    labels = {
#      env = var.project_id
#    }
#
#    machine_type = "n1-standard-2"
#    preemptible  = true
#    tags         = ["gke-node", "${var.project_id}-gke"]
#    metadata = {
#      disable-legacy-endpoints = "true"
#    }
#  }
#}
