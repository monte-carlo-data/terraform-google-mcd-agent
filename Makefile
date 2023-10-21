.PHONY: default sanity-check

default:
	@echo "Read the readme"

sanity-check:
	terraform init -backend=false
	terraform fmt -recursive -check -diff
	terraform validate