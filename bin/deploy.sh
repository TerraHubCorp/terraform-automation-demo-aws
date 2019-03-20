#!/usr/bin/env bash

aws --version > /dev/null 2>&1 || { echo >&2 "aws is missing. aborting..."; exit 1; }
npm --version > /dev/null 2>&1 || { echo >&2 "npm is missing. aborting..."; exit 1; }
export NODE_PATH="$(npm root -g)"

if [ -z "${BRANCH_FROM}" ]; then BRANCH_FROM = "dev"; fi
if [ -z "${BRANCH_TO}" ]; then BRANCH_TO = "dev"; fi
if [ "${BRANCH_TO}" != "dev" ]; then THUB_ENV="-e ${BRANCH_TO}"; fi
if [ "${THUB_STATE}" == "approved" ]; then THUB_APPLY="-a"; fi

git --version > /dev/null 2>&1 || { echo >&2 "git is missing. aborting..."; exit 1; }
git checkout $BRANCH_TO
git checkout $BRANCH_FROM

terrahub --version > /dev/null 2>&1 || { echo >&2 "terrahub is missing. aborting..."; exit 1; }
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --output=text --query='Account')"
terrahub configure -c template.locals.account_id="${AWS_ACCOUNT_ID}"

terrahub configure -c template.terraform.backend -D -y -I ".*"
terrahub configure -c template.terraform.backend.s3.bucket="data-lake-terrahub-us-east-1"
terrahub configure -c template.terraform.backend.s3.region="us-east-1"
terrahub configure -c template.terraform.backend.s3.workspace_key_prefix="terraform_workspaces"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/api_gateway_deployment/terraform.tfstate" -i "api_gateway_deployment"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/api_gateway_rest_api/terraform.tfstate" -i "api_gateway_rest_api"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/iam_role/terraform.tfstate" -i "iam_role"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/lambda/terraform.tfstate" -i "lambda"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/security_group/terraform.tfstate" -i "security_group"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/subnet_private/terraform.tfstate" -i "subnet_private"
terrahub configure -c template.terraform.backend.s3.key="terraform/terrahubcorp/demo-terraform-automation-aws/vpc/terraform.tfstate" -i "vpc"

terrahub run -y -b ${THUB_APPLY} ${THUB_ENV}