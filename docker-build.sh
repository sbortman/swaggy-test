#!/bin/bash
#=================================================================================
#
# Performs a build of all O2 docker images. Previous O2 images are removed from
# the local docker instance. The images are pushed to the docker hub registry
#
#=================================================================================

#--------------- BEGIN EXECUTION -------------------------------
# Uncomment for line-by-line script sebugging:
#PS4='$LINENO: ' ; set -x

export AWS_ACCOUNT_ID="433455360279"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="AKIAIOC3FXMG6UCXZAGQ"
export AWS_SECRET_ACCESS_KEY="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"
export DOCKER_REGISTRY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

# Create login credentials for docker
echo; echo "Attempting to log into Amazon container registry..."
docker_login_cmd=" $(aws ecr get-login --registry-ids $AWS_ACCOUNT_ID)"
if [ -z "$docker_login_cmd" ] ; then
  echo "Unable to create login credential for amazonaws access!"
  exit 1
else
  $docker_login_cmd
  if [ $? != 0 ] ; then
    echo "Unable to login to docker instance!"
    exit 1
  else
    echo "Successfully logged into docker"
  fi
fi

#aws ecr create-repository --repository-name swaggy-test
#if [ $? -ne 0 ]; then
#  echo "Unable to create repository"
#  exit 1
#fi

./gradlew build
if [ $? -ne 0 ]; then
  echo; echo "Error encountered while performing gradlew build in $PWD"
  popd
  exit 1
fi

docker build -t swaggy-test:latest .
if [ $? -ne 0 ]; then
  echo; echo "ERROR: Building container image"
  popd
  exit 1
fi

docker push ${DOCKER_REGISTRY_URI}/swaggy-test:latest
if [ $? -ne 0 ]; then
  echo; echo "ERROR: Pushing container image"
  popd
  exit 1
fi

exit 0
