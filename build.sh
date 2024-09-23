#!/bin/bash

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

if [ -f config.yaml ]; then
    eval $(parse_yaml config.yaml)
else
    echo "config.yaml not found. Please create it with necessary variables."
    exit 1
fi

BACKEND_IMAGE_NAME=${BACKEND_IMAGE_NAME:-"app/backend"}
FRONTEND_IMAGE_NAME=${FRONTEND_IMAGE_NAME:-"app/frontend"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-""}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--tag)
    IMAGE_TAG="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--registry)
    DOCKER_REGISTRY="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

build_and_push() {
    local dockerfile=$1
    local image_name=$2
    local full_image_name="${DOCKER_REGISTRY:+$DOCKER_REGISTRY/}$image_name:$IMAGE_TAG"
    
    echo "Building Docker image: $full_image_name"
    docker build -f $dockerfile --cache-from $full_image_name -t $full_image_name .
    
    if [ -n "$DOCKER_REGISTRY" ]; then
        echo "Pushing image to registry: $full_image_name"
        docker push $full_image_name
    else
        echo "No registry specified. Skipping push for $full_image_name"
    fi
}

build_and_push "Dockerfile.backend" $BACKEND_IMAGE_NAME

build_and_push "Dockerfile.frontend" $FRONTEND_IMAGE_NAME

echo "Build and push completed for both services"
