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
  description = "Ingress setting for the CloudRun service, one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_ONLY"], var.ingress)
    error_message = "Invalid ingress setting. Must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}

variable "custom_audiences" {
  description = "Custom audiences for the CloudRun service, for example ['https://example.loadbalancer.com']. For more information check: https://cloud.google.com/run/docs/configuring/custom-audiences."
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "Deletion protection setting for the CloudRun service."
  type        = bool
  default     = false
}

variable "vpc_access" {
  description = "VPC Access settings for the CloudRun service. See the example under examples/agent_vpc."
  type = object({
    egress    = string           # "ALL_TRAFFIC" or "PRIVATE_RANGES_ONLY"
    connector = optional(string) # VPC Access connector name, format: projects/{project}/locations/{location}/connectors/{connector}, where {project} can be project id or number

    network_interfaces = optional(object({
      network    = optional(string)
      subnetwork = optional(string)
    }))
  })
  default = null
  validation {
    condition     = var.vpc_access == null ? true : contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_access.egress)
    error_message = "Invalid egress setting. Must be one of: ALL_TRAFFIC, PRIVATE_RANGES_ONLY."
  }
}
