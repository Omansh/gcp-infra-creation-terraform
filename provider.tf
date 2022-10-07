terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.38.0"
    }
  }
}

provider "google" {
  project     = "terrafrom-gcp-364213"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = file(var.path)
}