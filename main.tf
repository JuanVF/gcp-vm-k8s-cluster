module "cluster" {
  source                    = "./cluster"
  project_id                = var.project_id
  region                    = var.region
  zone                      = var.zone
  private_key               = var.private_key
  network_name              = "cluster"
  master_node_machine_type  = "c2d-standard-2"
  worker_node_machine_types = ["n1-standard-2", "e2-medium"]
}
