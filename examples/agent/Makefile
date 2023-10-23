.PHONY: default apply activate test exec clean

default:
	@echo "Read the readme"

sleep-%:
	sleep $(@:sleep-%=%)

apply:
	# Apply this example.
	terraform init && terraform apply -auto-approve

activate:
	# Activate the SA.
	# This command expects that you have have applied this example with key generation toggled.
	bash -c 'gcloud auth activate-service-account --key-file <(terraform output -json ''key'' | jq -r ''.[0]'' | base64 -d)'

test:
	# Test agent reachability via the health endpoint.
	# This command expects that you have have applied and activated this example.
	curl --location "$$(terraform output --raw uri)/api/v1/test/health" --header "Authorization: Bearer $$(gcloud auth print-identity-token)" | jq '.'

exec: apply activate sleep-60 test  # Sleep to wait on initial CR SA propagation. Subsequent usage should require no delay.

clean:
	# Delete this example.
	# WARNING -- This command will delete resources and local state files. This is unrecoverable.
	terraform destroy -auto-approve && rm -rf .terraform* terraform.tfstate*
