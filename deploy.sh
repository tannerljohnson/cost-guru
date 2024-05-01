#!/usr/bin/env bash

set -o errexit
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
  echo "Usage: ./deploy.sh
This script will build and push a new image for artemis:latest
"
  exit
fi

echo "Stashing changes and pulling main:HEAD..."
#git add .
#git stash
#git checkout main
#git pull

AWS_ACCOUNT_ID="719898615513"
AWS_REGION="us-west-2"
SSO_PROFILE="playground/infrastructure-admin"
REGISTRY_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
REPOSITORY_NAME="artemis"

echo "Fetching ECR credentials and logging into docker..."
aws ecr get-login-password --region $AWS_REGION --profile $SSO_PROFILE | docker login \
              --username AWS \
              --password-stdin $REGISTRY_URL

echo "Building new image..."
docker build -t artemis:latest .

echo "Tagging image..."
docker tag artemis:latest "$REGISTRY_URL/$REPOSITORY_NAME:latest"

echo "Pushing image..."
docker push "$REGISTRY_URL/$REPOSITORY_NAME:latest"

echo "Done!"
