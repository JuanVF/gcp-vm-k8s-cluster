data "google_compute_zones" "cluster_compute_zones" {
  region  = var.region
  project = var.project_id
}

locals {
  type            = ["public", "private"]
  zones           = data.google_compute_zones.cluster_compute_zones.names
  ssh_tag         = "ssh-access"
  master_node_tag = "master-node"
  worker_node_tag = "worker-node"
}

resource "google_storage_bucket" "cluster_bucket_info" {
  name          = "${var.project_id}-bucket"
  location      = "us-central1"
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_compute_instance" "cluster_master_node" {
  name         = "${var.project_id}-cluster-master-node"
  zone         = var.zone
  machine_type = var.master_node_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.cluster_vpc_network.id
    subnetwork = google_compute_subnetwork.cluster_vpc_subnetwork.id

    network_ip = "10.10.10.2"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("${path.module}/scripts/setup_master_node.sh", {
      project_id                  = var.project_id
      bucket_name                 = google_storage_bucket.cluster_bucket_info.name
      service_account_private_key = var.private_key
    })
  }

  depends_on = [
    google_compute_subnetwork.cluster_vpc_subnetwork,
    google_compute_network.cluster_vpc_network,
    google_storage_bucket.cluster_bucket_info
  ]
  tags = [local.ssh_tag, local.master_node_tag]
}

resource "google_compute_instance" "cluster_worker_nodes" {
  count        = length(var.worker_node_machine_types)
  name         = "${var.project_id}-cluster-worker-node-${count.index}"
  zone         = var.zone
  machine_type = var.worker_node_machine_types[count.index]

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.cluster_vpc_network.id
    subnetwork = google_compute_subnetwork.cluster_vpc_subnetwork.id

    network_ip = "10.10.10.${3 + count.index}"
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("${path.module}/scripts/setup_worker_node.sh", {
      project_id                  = var.project_id
      bucket_name                 = google_storage_bucket.cluster_bucket_info.name
      service_account_private_key = var.private_key
      worker_number               = count.index
    })
  }

  depends_on = [google_compute_instance.cluster_master_node]
  tags       = [local.ssh_tag, local.worker_node_tag]
}
