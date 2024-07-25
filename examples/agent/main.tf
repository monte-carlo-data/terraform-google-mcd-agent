module "apollo" {
  source = "../../"

  remote_upgradable = true
  generate_key      = true
  project_id        = "mc-dev-data-collector"
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