terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # For production, configure a GCS backend here.
  # backend "gcs" {
  #   bucket = "your-tf-state-bucket"
  #   prefix = "devops-lab-1"
  # }
}

variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Default deployment region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
