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


function createRepositories()
{
  local repositories=$1[@]
  local currentRepositories=`aws ecr describe-repositories --registry-id ${AWS_ACCOUNT_ID}`
  local a=("${!repositories}")
  for i in "${a[@]}" ; do
     local repo_path="$i"
     if [ -n $DOCKER_REGISTRY_NAMESPACE ]; then
       repo_path="$DOCKER_REGISTRY_NAMESPACE-$i"
     fi
     local repoCheck=`echo $currentRepositories | grep $repo_path`
     if [ -z "$repoCheck" ] ; then
        echo "Creating repository <$repo_path>"
        aws ecr create-repository --repository-name $repo_path
        if [ $? -ne 0 ]; then
          echo "Unable to create repository $repo_path"
          return $?
        fi
     fi
  done
  return 0
}


export DOCKER_REGISTRY_URI="433455360279"
export AWS_ACCOUNT_ID="433455360279"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="AKIAIOC3FXMG6UCXZAGQ"
export AWS_SECRET_ACCESS_KEY="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"

# Create login credentials for docker
if [[ "$DOCKER_REGISTRY_URI" =~ .*amazonaws.* ]] ; then
  echo; echo "Attempting to log into Amazon container registry..."
  docker_login_cmd=" $(aws ecr get-login --registry-ids $AWS_ACCOUNT_ID)"
  if [ -z "$docker_login_cmd" ] ; then
    echo "Unable to create login credential for amazonaws access!"
    exit 1
  else
    echo "####################"; echo "docker_login_cmd = <$docker_login_cmd>"; echo "####################"
    $docker_login_cmd
    if [ $? != 0 ] ; then
      echo "Unable to login to docker instance!"
      exit 1
    else
      echo "Successfully logged into docker"
    fi
  fi
fi


aws ecr create-repository --repository-name swaggy-test-container
if [ $? -ne 0 ]; then
  echo "Unable to create repository"
  return $?
fi

pushd `dirname $0` >/dev/null
export SCRIPT_DIR=`pwd -P`
popd >/dev/null

pushd swaggy-test
./gradlew build
if [ $? -ne 0 ]; then
  echo; echo "Error encountered while performing gradlew build in $PWD"
  popd
  exit 1
fi

docker build -t swaggy-test:latest .
if [ $? -ne 0 ]; then
  echo; echo "ERROR: Building container"
  popd
  exit 1
fi

docker push ${DOCKER_REGISTRY_URI}/swaggy-test:latest




# Loop to build docker images and push them to container registry:
for app_name in ${SPRING_CLOUD_APPS[@]} ; do
  if [ -n $DOCKER_REGISTRY_NAMESPACE ]; then
    app="${DOCKER_REGISTRY_NAMESPACE}-${app_name}"
    o2_base_app="${DOCKER_REGISTRY_NAMESPACE}-o2-base"
  else
    app="${app_name}"
    o2_base_app="o2-base"
  fi

   echo "Building ${app} docker image"
   pushd ${app_name}

   # Build the jar needed later by the docker build:
   ./gradlew build
   if [ $? -ne 0 ]; then
     echo; echo "Error encountered while performing gradlew build in $PWD"
     popd
     exit 1
   fi

   getImageName ${app} ${TAG}

   # o2-base gets special treatment because it needs to know which OSSIM RPM repository to
   # pull from (dev or master). All others depend on o2-base layer based on TAG var:
   cp Dockerfile Dockerfile.back
   sed -i -e "s/FROM REGISTRY_URI\/o2-base/FROM $DOCKER_REGISTRY_URI\/${o2_base_app}\:${TAG}/" Dockerfile
   docker build --no-cache -t ${imagename} .
   build_status=$?
   mv Dockerfile.back Dockerfile
   if [ $build_status -ne 0 ]; then
     echo; echo "ERROR: Building container ${app} with tag ${TAG}"
     popd
     exit 1
   fi

   # Delete the old repo image first before push:
   deleteImage ${app} ${TAG}
   if [ $? -ne 0 ]; then
     echo; echo "ERROR: Deleting image ${app}:${TAG}"
     popd
     exit 1
   fi

   # The image is uploaded to the active container registry (see docker-common.sh for assignment)
   docker push ${imagename}
   if [ $? -ne 0 ]; then
     echo; echo "ERROR: Pushing container ${app} with tag ${TAG}"
     popd
     exit 1
   fi

   popd
done
