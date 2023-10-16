output "mcd_agent_name" {
  value       = var.remote_upgradable ? google_cloud_run_v2_service.mcd_agent_service_with_remote_upgrade_support[0].name : google_cloud_run_v2_service.mcd_agent_service[0].name
  description = "The name of the agent Cloud Run service."
}

output "mcd_agent_uri" {
  value       = var.remote_upgradable ? google_cloud_run_v2_service.mcd_agent_service_with_remote_upgrade_support[0].uri : google_cloud_run_v2_service.mcd_agent_service[0].uri
  description = "The URL for the agent service. To be used in registering."
}

output "mcd_agent_storage" {
  value       = google_storage_bucket.mcd_agent_store.name
  description = "The GCS bucket for the agent."
}

output "mcd_agent_invoker_sa" {
  value       = google_service_account.mcd_agent_invoker_sa.email
  description = "The email of the invoker service account for the agent."
}

output "mcd_agent_invoker_key" {
  value       = length(google_service_account_key.mcd_agent_invoker_key) > 0 ? google_service_account_key.mcd_agent_invoker_key[*].private_key : null
  description = "The Key file for Monte Carlo to invoke the agent service. To be used in registering."
  sensitive   = true
} # Can save via `terraform output -json 'mcd_agent_invoker_key' | jq -r '.[0]' | base64 -d > mcd-agent-key.json`