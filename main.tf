locals {
  # Wrapper metadata
  mcd_wrapper_version       = "0.0.1"
  mcd_agent_platform        = "GCP"
  mcd_agent_service_name    = "REMOTE_AGENT"
  mcd_agent_deployment_type = "TERRAFORM"

  # Data store properties
  mcd_agent_store_name        = "mcd-agent-store-${random_id.mcd_agent_id.hex}"
  mcd_agent_store_data_prefix = "mcd/"

  # Cloud run properties
  mcd_agent_cr_name                             = "mcd-agent-service-${random_id.mcd_agent_id.hex}"
  mcd_agent_cr_min_instance_count               = 0
  mcd_agent_cr_max_instance_count               = 100
  mcd_agent_cr_timeout                          = "900s"
  mcd_agent_cr_cpu                              = "1000m"
  mcd_agent_cr_memory                           = "512Mi"
  mcd_agent_cr_max_instance_request_concurrency = 1
}

resource "random_id" "mcd_agent_id" {
  byte_length = 4
}

## ---------------------------------------------------------------------------------------------------------------------
## Agent Resources
## MCD agent core components: GCP Cloud Run for service execution and Cloud Storage for troubleshooting and temporary data.
## See details here: https://docs.getmontecarlo.com/docs/platform-architecture#customer-hosted-agent--object-storage-deployment
## ---------------------------------------------------------------------------------------------------------------------


resource "google_storage_bucket" "mcd_agent_store" {
  name     = local.mcd_agent_store_name
  location = var.location
  project  = var.project_id
  lifecycle_rule {
    condition {
      age            = 90
      matches_prefix = [local.mcd_agent_store_data_prefix]
    }
    action {
      type = "Delete"
    }
  }
  lifecycle_rule {
    condition {
      age            = 2
      matches_prefix = ["${local.mcd_agent_store_data_prefix}tmp"]
    }
    action {
      type = "Delete"
    }
  }
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

resource "google_project_iam_custom_role" "mcd_agent_role" {
  role_id = "mcdAgentRole${random_id.mcd_agent_id.hex}"
  title   = "MCD Agent Role"
  permissions = compact([
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    var.remote_upgradable ? "iam.serviceAccounts.actAs" : null,
    var.remote_upgradable ? "run.operations.get" : null
  ])
  project = var.project_id
}

resource "google_service_account" "mcd_agent_service_sa" {
  account_id   = "mcd-agent-service-sa-${random_id.mcd_agent_id.hex}"
  display_name = "MCD Agent Service SA"
  project      = var.project_id
}

resource "google_storage_bucket_iam_binding" "mcd_agent_service_sa_binding" {
  bucket = google_storage_bucket.mcd_agent_store.name
  role   = "projects/${var.project_id}/roles/${google_project_iam_custom_role.mcd_agent_role.role_id}"

  members = [
    "serviceAccount:${google_service_account.mcd_agent_service_sa.email}",
  ]
}

resource "google_cloud_run_v2_service" "mcd_agent_service" {
  count = var.remote_upgradable ? 0 : 1
  name  = local.mcd_agent_cr_name
  template {
    scaling {
      min_instance_count = local.mcd_agent_cr_min_instance_count
      max_instance_count = local.mcd_agent_cr_max_instance_count
    }
    timeout         = local.mcd_agent_cr_timeout
    service_account = google_service_account.mcd_agent_service_sa.email
    containers {
      image = var.image
      resources {
        limits = {
          cpu    = local.mcd_agent_cr_cpu
          memory = local.mcd_agent_cr_memory
        }
      }
      env {
        name  = "MCD_AGENT_IMAGE_TAG"
        value = var.image
      }
      env {
        name  = "MCD_AGENT_CLOUD_PLATFORM"
        value = local.mcd_agent_platform
      }
      env {
        name  = "MCD_AGENT_WRAPPER_TYPE"
        value = local.mcd_agent_deployment_type
      }
      env {
        name  = "MCD_AGENT_WRAPPER_VERSION"
        value = local.mcd_wrapper_version
      }
      env {
        name  = "MCD_AGENT_IS_REMOTE_UPGRADABLE"
        value = false
      }
      env {
        name  = "MCD_STORAGE_BUCKET_NAME"
        value = google_storage_bucket.mcd_agent_store.name
      }
    }
    max_instance_request_concurrency = local.mcd_agent_cr_max_instance_request_concurrency
  }
  location = var.location
  project  = var.project_id
}

# Terraform lifecycle meta arguments do not support conditions so two copies of the resource are required to ignore
# remote (agent sourced) image upgrades.
resource "google_cloud_run_v2_service" "mcd_agent_service_with_remote_upgrade_support" {
  count = var.remote_upgradable ? 1 : 0
  name  = local.mcd_agent_cr_name
  template {
    scaling {
      min_instance_count = local.mcd_agent_cr_min_instance_count
      max_instance_count = local.mcd_agent_cr_max_instance_count
    }
    timeout         = local.mcd_agent_cr_timeout
    service_account = google_service_account.mcd_agent_service_sa.email
    containers {
      image = var.image
      resources {
        limits = {
          cpu    = local.mcd_agent_cr_cpu
          memory = local.mcd_agent_cr_memory
        }
      }
      env {
        name  = "MCD_AGENT_IMAGE_TAG"
        value = var.image
      }
      env {
        name  = "MCD_AGENT_CLOUD_PLATFORM"
        value = local.mcd_agent_platform
      }
      env {
        name  = "MCD_AGENT_WRAPPER_TYPE"
        value = local.mcd_agent_deployment_type
      }
      env {
        name  = "MCD_AGENT_WRAPPER_VERSION"
        value = local.mcd_wrapper_version
      }
      env {
        name  = "MCD_AGENT_IS_REMOTE_UPGRADABLE"
        value = true
      }
      env {
        name  = "MCD_STORAGE_BUCKET_NAME"
        value = google_storage_bucket.mcd_agent_store.name
      }
    }
    max_instance_request_concurrency = local.mcd_agent_cr_max_instance_request_concurrency
  }
  location = var.location
  project  = var.project_id
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client
    ]
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## Invoker Resources
## MCD agent invoker service account and role. Allows Monte Carlo to submit requests to this agent.
## ---------------------------------------------------------------------------------------------------------------------


resource "google_service_account" "mcd_agent_invoker_sa" {
  account_id   = "mcd-agent-invoker-sa-${random_id.mcd_agent_id.hex}"
  display_name = "MCD Agent Invoker SA"
  project      = var.project_id
}

resource "google_cloud_run_service_iam_binding" "mcd_agent_invoker_sa_default_binding" {
  location = var.location
  project  = var.project_id
  service  = var.remote_upgradable ? google_cloud_run_v2_service.mcd_agent_service_with_remote_upgrade_support[0].name : google_cloud_run_v2_service.mcd_agent_service[0].name
  role     = "roles/run.invoker"
  members = [
    "serviceAccount:${google_service_account.mcd_agent_invoker_sa.email}",
  ]
}

resource "google_cloud_run_service_iam_binding" "mcd_agent_invoker_sa_remote_binding" {
  count    = var.remote_upgradable ? 1 : 0
  location = var.location
  project  = var.project_id
  service  = google_cloud_run_v2_service.mcd_agent_service_with_remote_upgrade_support[0].name
  role     = "roles/run.developer"
  members = [
    "serviceAccount:${google_service_account.mcd_agent_invoker_sa.email}",
  ]
}

resource "google_service_account_key" "mcd_agent_invoker_key" {
  count              = var.generate_key ? 1 : 0
  service_account_id = google_service_account.mcd_agent_invoker_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}