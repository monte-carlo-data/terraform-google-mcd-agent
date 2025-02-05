locals {
  project_id = "mc-dev-data-collector"
  location   = "us-east4"
}

provider "google" {
  project = local.project_id
  region  = local.location
}

resource "google_compute_network" "agent-vpc" {
  name                    = "agent-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "agent-vpc-default" {
  name          = "agent-vpc-default"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.agent-vpc.id
  region        = local.location

  private_ip_google_access = true
}


module "apollo" {
  source = "../../"

  remote_upgradable = true
  generate_key      = true
  project_id        = local.project_id
  location          = local.location
  vpc_access = {
    egress = "ALL_TRAFFIC" # route all traffic to the VPC
    network_interfaces = {
      network    = google_compute_network.agent-vpc.name
      subnetwork = google_compute_subnetwork.agent-vpc-default.name
    }
  }
}

output "uri" {
  value       = module.apollo.mcd_agent_uri
  description = "The URL for the agent."
}

output "key" {
  value       = module.apollo.mcd_agent_invoker_key
  description = "The Key file for Monte Carlo to invoke the agent."
  sensitive   = true
}