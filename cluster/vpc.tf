resource "google_compute_network" "cluster_vpc_network" {
  project                 = var.project_id
  name                    = "${var.project_id}-${var.network_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "cluster_vpc_subnetwork" {
  name                     = "${var.project_id}-${var.network_name}-subnetwork"
  region                   = var.region
  ip_cidr_range            = "10.10.10.0/24"
  network                  = google_compute_network.cluster_vpc_network.id
  private_ip_google_access = true

  depends_on = [google_compute_network.cluster_vpc_network]
}

resource "google_compute_firewall" "cluster_ssh_firewall" {
  name    = "${var.project_id}-${var.network_name}-ssh-firewall"
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

resource "google_compute_firewall" "cluster_master_firewall" {
  name    = "${var.project_id}-${var.network_name}-master-firewall"
  network = google_compute_network.cluster_vpc_network.id

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = [
      "80",          # Internet Protocol
      "6443",        # K8S API
      "2379-2380",   # etcd server client api
      "10250",       # kubelet api
      "30000-32767", # nodeports 
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.master_node_tag]
}

resource "google_compute_firewall" "cluster_outbound_firewall" {
  name    = "${var.project_id}-${var.network_name}-outbound-firewall"
  network = google_compute_network.cluster_vpc_network.id

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.master_node_tag]
}

resource "google_compute_router" "cluster_router" {
  name    = "${var.project_id}-${var.network_name}-router"
  project = var.project_id
  network = google_compute_network.cluster_vpc_network.name
  region  = var.region

  depends_on = [google_compute_network.cluster_vpc_network]
}

resource "google_compute_router_nat" "cluster_router_nat" {
  name                               = "${var.project_id}-${var.network_name}-router-nat"
  router                             = google_compute_router.cluster_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  depends_on = [google_compute_router.cluster_router]
}
