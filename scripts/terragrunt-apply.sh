#!/usr/bin/env bash
TERRAGRUNT_CONFIG=$2
cd $1 && \
git config --global url."https://token:${GH_TOKEN}@github.com/emisgroup".insteadOf "https://github.com/emisgroup"
git config --global --add url."https://token:${GH_TOKEN}@github.com".insteadOf "ssh://git@github.com"
terragrunt apply -compact-warnings --terragrunt-forward-tf-stdout -auto-approve --terragrunt-config $TERRAGRUNT_CONFIG --terragrunt-non-interactive
