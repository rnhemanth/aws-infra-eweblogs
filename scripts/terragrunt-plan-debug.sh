#!/usr/bin/env bash
TERRAGRUNT_CONFIG=$2
cd $1 && \
ls -l
ls -l $TERRAGRUNT_CONFIG
git config --global url."https://token:${GH_TOKEN}@github.com/emisgroup".insteadOf "https://github.com/emisgroup"
git config --global --add url."https://token:${GH_TOKEN}@github.com".insteadOf "ssh://git@github.com"
terragrunt plan --terragrunt-log-level debug -compact-warnings --terragrunt-forward-tf-stdout -out plan.out --terragrunt-config $TERRAGRUNT_CONFIG --terragrunt-non-interactive && terraform show -no-color plan.out > comment_plan.out

sed -i '1s/^/\`\`\`/' comment_plan.out
echo "\`\`\`" >> comment_plan.out
