setup:
	@echo "- Installing Terragrunt..."
	./scripts/install-terragrunt.sh
	@echo "✔ Done"

terragrunt-plan:
	@echo "- Planning terraform..."
	./scripts/terragrunt-plan.sh ${terraform_folder} ${terragrunt_config}
	@echo "✔ Done"

terragrunt-plan-debug:
	@echo "- Planning terraform with debug..."
	./scripts/terragrunt-plan-debug.sh ${terraform_folder} ${terragrunt_config}
	@echo "✔ Done"

terragrunt-apply:
	@echo "- Deploying terraform..."
	./scripts/terragrunt-apply.sh ${terraform_folder} ${terragrunt_config}
	@echo "✔ Done"

terragrunt-destroy:
	@echo "- Deploying terraform..."
	./scripts/terragrunt-destroy.sh ${terraform_folder} ${terragrunt_config}
	@echo "✔ Done"

terragrunt-destroy-plan:
	@echo "- Planning terraform destroy..."
	./scripts/terragrunt-plan-destroy.sh ${terraform_folder} ${terragrunt_config}
	@echo "✔ Done"