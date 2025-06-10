#!/usr/bin/env bash
# Temporarily install terragrunt, whilst we wait for https://github.com/emisgroup/jenkins-infrastructure/issues/1411
# Find Terragrunt
TERRAGRUNT=$(which terragrunt)

if [ -z "$TERRAGRUNT" ]; then
	LATEST_URL=$(curl -sL  https://api.github.com/repos/gruntwork-io/terragrunt/releases  | jq -r '.[0].assets[].browser_download_url' | grep -E 'linux.*amd64' | tail -1)
	curl -sL "$LATEST_URL" > /usr/local/bin/terragrunt
	chmod +x /usr/local/bin/terragrunt

	echo "Installed: Terragrunt $(/usr/local/bin/terragrunt | grep -iA 2 version | tr -d '\n')"
else
	printf "Terragrunt is already installed!\\n"
	exit
fi

# Find terragrunt, again
TERRAGRUNT=$(which terragrunt)

# Check for terragrunt after installation
if [ -z "$TERRAGRUNT" ]; then
	printf "Terragrunt installation failed\\n"
	exit 1
else
	printf "Terragrunt installation succeeded!\\n"
	terragrunt --version
	terraform --version
fi
