# Agent Sample
This example deploys a pre-release Monte Carlo Agent with remote upgrades and key generation enabled.

Note that this will persist a key in the remote state used by Terraform. Please take appropriate measures to protect your remote state.

Also, the pre-release agent is in active development and not intended for production usage. 

## Prerequisites
See the Prerequisites subsection in the module.

## Usage 
To provision this example and access (test) the agent locally:
```
terraform init
terraform apply

gcloud auth activate-service-account --key-file <(terraform output -json 'key' | jq -r '.[0]' | base64 -d)   

curl --location "$(terraform output --raw uri)/api/v1/test/health" --header "Authorization: Bearer $(gcloud auth print-identity-token)"
```
See [here](https://github.com/monte-carlo-data/apollo-agent) for agent usage and docs. You should be able to use any endpoint as documented. 
And don't forget to delete any resources when you're done (e.g. `terraform destroy` and revoking the SA locally). 

## Addendum
During development, you might want configure Terraform Cloud as the backend. To do so you can add the following snippet: 
```
terraform {
  cloud {
    organization = "<org>"

    workspaces {
      name = "<workspace>"
    }
  }
}
```
This also requires you to execute `terraform login` before initializing. You will also either have to update the 
working directory to include the agent module or set the execution mode to "Local".