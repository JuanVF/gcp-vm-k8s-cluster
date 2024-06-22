module "cluster" {
  source                   = "./cluster"
  project_id               = var.project_id
  region                   = var.region
  zone                     = var.zone
  network_name             = "cluster"
  master_node_machine_type = "e2-medium"
}
