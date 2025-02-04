variable "project_id" {
  description = "The GCP project ID to deploy the agent into."
  type        = string
}

variable "location" {
  description = "The GCP location (region) to deploy the agent into."
  type        = string
  default     = "us-east4" # Northern Virginia
}

variable "image" {
  description = "The image for the agent."
  type        = string
  default     = "montecarlodata/agent:latest-cloudrun"
}

variable "remote_upgradable" {
  description = <<EOF
    Allow the agent image to be remotely upgraded by Monte Carlo.

    Note that this sets a lifecycle to ignore any changes in Terraform to the image used after the initial deployment.

    If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements.

    Changing this value after initial deployment will replace your agent and require (re)registration.
  EOF  
  type        = bool
  default     = true
}

variable "generate_key" {
  description = <<EOF
    Whether to generate a key for Monte Carlo to invoke the agent via Terraform.

    Note that this will persist a key in the remote state used by Terraform. Please take appropriate measures to protect your remote state.

    If not set to 'true' you will need to create a JSON key via another mechanism (e.g. GCP console) before registration.
  EOF
  type        = bool
}

variable "ingress" {
  description = "Ingress setting for the CloudRun service"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "custom_audiences" {
  description = "Custom audiences for the CloudRun service"
  type        = list(string)
  default     = []
}

variable "vpc_access" {
    description = "VPC Access settings for the CloudRun service"
    type        = object({
      egress    = string
      connector = optional(string)

      network_interfaces = optional(object({
        network    = optional(string)
        subnetwork = optional(string)
      }))
    })
    default = null
}