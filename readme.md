# Automated Kubernetes Cluster Setup on Google Cloud Platform

This is just for learning purposes. The Cluster as result is not stable enough! Don't use it in
production without making stability improvements first.

## Description

This project aims to automate the setup of a Kubernetes cluster on Google Cloud Platform (GCP) using Terraform and shell scripts. It includes the provisioning of infrastructure, setting up master and worker nodes, and installing necessary software and configurations.

## Prerequisites

- Terraform
- Google Cloud SDK
- GCP account with appropriate permissions
- A GCP Service Account Private Key with Compute Storage Access
- A bucket in GCP Storage for sharing the join command between nodes

## Setup Instructions

1. Clone the repository

> git clone git@github.com:JuanVF/gcp-vm-k8s-cluster.git
> cd gcp-vm-k8s-cluster

2. Configure Terraform variables

You need to setup the variables to interact with GCP. Create a `terraform.tfvars` and add these variables

```hcl
project_id  = "<project-id>"
region      = "us-central1"
zone        = "us-central1-a"
private_key = "<svc account private key>"
```

3. Initialize Terraform

> terraform init

4. Apply Terraform configurations

> terraform apply

5. At this point you should just wait for the Cluster to be available!
