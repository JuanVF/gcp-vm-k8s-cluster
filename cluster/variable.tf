variable "project_id" {
  description = "GCP Project"
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Region Zone"
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The VPC Name"
  default     = "cluster"
}

variable "master_node_machine_type" {
  description = "The Cluster Master Node Machine Type"
  default     = "e2-medium"
}

variable "worker_node_machine_types" {
  description = "The Cluster Worker Nodes Machine Types"
  type        = list(string)
  default     = ["e2-medium", "e2-medium"]
}

variable "private_key" {
  description = "GCP Service Account Private Key with Cloud Storage Access"
}
