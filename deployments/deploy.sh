#!/bin/bash

if [ -f config.yaml ]; then
    export $(grep -v '^#' config.yaml | xargs)
else
    echo "config.yaml not found. Please create it with necessary variables."
    exit 1
fi

ENVIRONMENT=${ENVIRONMENT:-"development"}
NAMESPACE=${NAMESPACE:-"default"}
BACKEND_VERSION=${BACKEND_VERSION:-"latest"}
FRONTEND_VERSION=${FRONTEND_VERSION:-"latest"}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -e|--environment)
    ENVIRONMENT="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--namespace)
    NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

case $ENVIRONMENT in
    "production")
        HOST="prod.hackathon.local"
        ;;
    "staging")
        HOST="staging.hackathon.local"
        ;;
    *)
        HOST="dev.hackathon.local"
        ;;
esac

apply_manifest() {
    local file=$1
    echo "Applying $file..."
    sed -e "s|\${NAMESPACE}|$NAMESPACE|g" \
        -e "s|\${BACKEND_VERSION}|$BACKEND_VERSION|g" \
        -e "s|\${FRONTEND_VERSION}|$FRONTEND_VERSION|g" \
        -e "s|\${HOST}|$HOST|g" \
        "$file" | kubectl apply -f -
}

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

apply_manifest "backend.yaml"
apply_manifest "frontend.yaml"
apply_manifest "ingress.yaml"

echo "Deployment completed for $ENVIRONMENT environment in namespace $NAMESPACE"
echo "Application is accessible at http://$HOST"
