data "google_compute_zones" "cluster_compute_zones" {
  region  = var.region
  project = var.project_id
}

locals {
  type    = ["public", "private"]
  zones   = data.google_compute_zones.cluster_compute_zones.names
  ssh_tag = "ssh-access"
}

resource "google_compute_network" "cluster_vpc_network" {
  project                 = var.project_id
  name                    = "${var.network_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "cluster_vpc_subnetwork" {
  name                     = "${var.network_name}-subnetwork"
  region                   = var.region
  ip_cidr_range            = "10.10.10.0/24"
  network                  = google_compute_network.cluster_vpc_network.id
  private_ip_google_access = true

  depends_on = [google_compute_network.cluster_vpc_network]
}

resource "google_compute_firewall" "cluster_ssh_firewall" {
  name    = "${var.network_name}-ssh-firewall"
  network = google_compute_network.cluster_vpc_network.id

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Enable All Traffic, This is for TESTING CHANGE IT IF USING IT
  # FOR A REAL PRODUCT!
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.ssh_tag]
}

resource "google_compute_router" "cluster_router" {
  name    = "${var.network_name}-router"
  project = var.project_id
  network = google_compute_network.cluster_vpc_network.name
  region  = var.region

  depends_on = [google_compute_network.cluster_vpc_network]
}

resource "google_compute_router_nat" "cluster_router_nat" {
  name                               = "${var.network_name}-router-nat"
  router                             = google_compute_router.cluster_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  depends_on = [google_compute_router.cluster_router]
}

resource "google_compute_instance" "cluster_master_node" {
  name         = "cluster-master-node"
  zone         = var.zone
  machine_type = var.master_node_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2404-lts-amd64"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.cluster_vpc_network.id
    subnetwork = google_compute_subnetwork.cluster_vpc_subnetwork.id

    network_ip = "10.10.10.8"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  depends_on = [google_compute_subnetwork.cluster_vpc_subnetwork, google_compute_network.cluster_vpc_network]
  tags       = [local.ssh_tag]
}
