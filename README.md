# Monte Carlo GCP Agent Module (Beta)

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent) (Beta) on GCP
Cloud Run, along with storage, roles and service accounts.

See [here](https://docs.getmontecarlo.com/docs/platform-architecture) for architecture details and alternative
deployment options.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install).
  [Authentication reference](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)

## Usage

Basic usage of this module:

```
module "apollo" {
  source = "monte-carlo-data/mcd-agent/google"
  version = "0.1.1"

  # Required variables
  generate_key      = true
  project_id        = "<GCP PROJECT>"
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
```

After which you must register your agent with Monte Carlo. See
[here](https://docs.getmontecarlo.com/docs/create-and-register-a-gcp-agent) for more details, options, and
documentation.

Note that setting `generate_key = true` will persist a key in the remote state used by Terraform. Please take
appropriate measures to protect your remote state.

This module also activates the Cloud Run API in the project you specified. This resource (API) is not deactivated on
destroy.

## Inputs

| Name              | Description                                                                                                                                                                                                                                                                                                                                                                                                                   | Type   | Default                              |
|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|--------------------------------------|
| project_id        | The GCP project ID to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                                  | string | N/A                                  |
| location          | The GCP location (region) to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                           | string | us-east4                             |
| image             | The image for the agent.                                                                                                                                                                                                                                                                                                                                                                                                      | string | montecarlodata/agent:latest-cloudrun |
| remote_upgradable | Allow the agent image to be remotely upgraded by  Monte Carlo. Note that this sets a lifecycle to ignore any  changes in Terraform to the image used after the initial  deployment. If not set to 'true' you will be responsible for  upgrading the image (e.g. specifying a new tag) for any bug  fixes and improvements. Changing this value after initial deployment will replace your agent and require (re)registration. | bool   | true                                 |
| generate_key      | Whether to generate a key for Monte Carlo to invoke the agent via Terraform. Note that this will persist a key in the remote state used by Terraform. Please take appropriate measures to protect your remote state. If not set to 'true' you will need to create a JSON key via another mechanism (e.g. GCP console) before registration.                                                                                    | bool   | N/A                                  |

## Outputs

| Name                  | Description                                                                          |
|-----------------------|--------------------------------------------------------------------------------------|
| mcd_agent_name        | The name of the agent Cloud Run service.                                             |
| mcd_agent_uri         | The URL for the agent service. To be used in registering.                            |
| mcd_agent_storage     | The GCS bucket for the agent.                                                        |
| mcd_agent_invoker_sa  | The email of the invoker service account for the agent.                              |
| mcd_agent_invoker_key | The Key file for Monte Carlo to invoke the agent service. To be used in registering. |

## Releases and Development

The README and sample agent in the `examples/agent` directory is a good starting point to familiarize
yourself with using the agent. These [docs](https://cloud.google.com/docs/terraform) are also helpful to learn about
provisioning resources in GCP.

Note that all Terraform files must conform to the standards of `terraform fmt` and
the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop).
CircleCI will sanity check formatting and for valid tf config files.
It is also recommended you use Terraform Cloud as a backend.
Otherwise, as normal, please follow Monte Carlo's code guidelines during development and review.

When ready to release simply add a new version tag, e.g. v0.0.42, and push that tag to GitHub.
See additional
details [here](https://developer.hashicorp.com/terraform/registry/modules/publish#releasing-new-versions).

## License

See [LICENSE](https://github.com/monte-carlo-data/terraform-google-mcd-agent/blob/main/LICENSE) for more information.

## Security

See [SECURITY](https://github.com/monte-carlo-data/terraform-google-mcd-agent/blob/main/SECURITY.md) for more information.