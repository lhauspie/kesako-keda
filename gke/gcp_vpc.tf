# VPC
resource "google_compute_network" "network" {
  name                    = "${var.project_id}-network"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.network.name
  ip_cidr_range = "10.10.0.0/24"
}
