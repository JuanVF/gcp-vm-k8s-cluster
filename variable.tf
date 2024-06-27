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

variable "private_key" {
  description = "GCP Service Account Private Key with Cloud Storage Access in base64"
}
