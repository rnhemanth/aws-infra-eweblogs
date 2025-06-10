bootstrap-dev:
	@echo "- Bootstrap dev environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap dev eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform
	@echo "✔ Done"

bootstrap-stg:
	@echo "- Bootstrap stg environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap stg eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform
	@echo "✔ Done"

bootstrap-prd:
	@echo "- Bootstrap prd environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap prd eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform
	@echo "✔ Done"

destory-role-dev:
	@echo "- Destroying role indev environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap dev eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform destroy
	@echo "✔ Done"

destory-role-stg:
	@echo "- Destroying role instg environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap stg eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform destroy
	@echo "✔ Done"

destory-role-prd:
	@echo "- Destroying role in prd environment..."
	chmod +x ./eweblogs/bootstrap/setup
	./eweblogs/bootstrap/setup bootstrap prd eweblogs england eu-west-2 aws-infra-deploy-eweblogs eweblogs-platform destroy
	@echo "✔ Done"
