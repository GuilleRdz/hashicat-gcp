# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=3.68.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "hashicat" {
  name                    = "${var.prefix}-vpc-${var.region}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "hashicat" {
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.hashicat.self_link
  ip_cidr_range = var.subnet_prefix
}

resource "google_compute_firewall" "http-server" {
  name    = "${var.prefix}-default-allow-ssh-http"
  network = google_compute_network.hashicat.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "google_compute_instance" "hashicat" {
  name         = "${var.prefix}-hashicat"
  zone         = "${var.region}-b"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.hashicat.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["http-server"]

  labels = {
    name = "hashicat"
    department = "devops"
    billable = "devops"
  }

}
