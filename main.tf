terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. Dedicated VPC and Subnet
resource "google_compute_network" "hermes_vpc" {
  name                    = "hermes-agent-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "hermes_subnet" {
  name          = "hermes-agent-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.hermes_vpc.id
}

# 2. Firewall Rules for SSH and optional Web UI/Gateway (Port 8080)
resource "google_compute_firewall" "allow_ssh_and_gateway" {
  name    = "allow-ssh-and-gateway"
  network = google_compute_network.hermes_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9119"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["hermes-agent"]
}

# 3. Free Tier Eligible Compute Engine Instance
resource "google_compute_instance" "hermes_vm" {
  name         = "hermes-agent-vm"
  machine_type = "e2-micro" # Free Tier eligible
  zone         = var.zone

  tags = ["hermes-agent"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30 # Free tier includes up to 30 GB standard disk
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.hermes_vpc.id
    subnetwork = google_compute_subnetwork.hermes_subnet.id

    access_config {
      # Ephemeral public IP on Standard Tier networking for the larger
      # 200 GB/month Always Free egress allowance (vs 1 GB on Premium Tier)
      network_tier = "STANDARD"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  # Startup script to configure swap and install Hermes Agent dependencies
  metadata_startup_script = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail

    # 1. Allocate a 2GB swap space (prevents OOM on 1GB e2-micro RAM)
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    # 2. Update and install base packages
    apt-get update -y
    apt-get install -y curl git tmux ca-certificates python3 python3-pip

    # 3. Pre-install Hermes Agent into user environment
    su - ${var.ssh_user} -c 'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash' || true
  EOF
}
