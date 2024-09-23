#!/bin/bash

set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_homebrew() {
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew is already installed."
    fi
}

install_docker() {
    echo "Installing Docker..."
    if ! command_exists docker; then
        brew install --cask docker
        open /Applications/Docker.app
        echo "Please wait for Docker to start and press any key to continue..."
        read -n 1 -s
    else
        echo "Docker is already installed."
    fi
}

install_docker_compose() {
    echo "Installing Docker Compose..."
    if ! command_exists docker-compose; then
        brew install docker-compose
    else
        echo "Docker Compose is already installed."
    fi
}

install_kind() {
    echo "Installing Kind..."
    if ! command_exists kind; then
        brew install kind
    else
        echo "Kind is already installed."
    fi
}

install_kubectl() {
    echo "Installing kubectl..."
    if ! command_exists kubectl; then
        brew install kubectl
    else
        echo "kubectl is already installed."
    fi
}

create_kind_cluster() {
    echo "Checking for existing Kind cluster..."
    if kind get clusters | grep -q "^hackathon-cluster$"; then
        echo "Kind cluster 'hackathon-cluster' already exists. Skipping creation."
    else
        echo "Creating Kind cluster..."
        kind create cluster --name hackathon-cluster
    fi
    kubectl cluster-info --context kind-hackathon-cluster
}

create_docker_local_registry() {
    if ! command -v docker &> /dev/null
    then
        echo "Docker is not installed. Please install Docker Desktop for Mac first."
        exit 1
    fi

    REGISTRY_NAME="local-registry"
    REGISTRY_PORT=5555

    if docker ps | grep -q $REGISTRY_NAME
    then
        echo "Local registry is already running."
    else
        docker run -d \
        --name $REGISTRY_NAME \
        -p $REGISTRY_PORT:5000 \
        --restart=always \
        registry:2

        echo "Local registry started on localhost:$REGISTRY_PORT"
    fi

    DOCKER_PREFERENCES="$HOME/Library/Group Containers/group.com.docker/settings.json"

    if [ ! -f "$DOCKER_PREFERENCES" ]; then
        echo "Docker Desktop preferences file not found. Please ensure Docker Desktop is installed and has been run at least once."
        exit 1
    fi

    if ! grep -q "localhost:$REGISTRY_PORT" "$DOCKER_PREFERENCES"; then
        cp "$DOCKER_PREFERENCES" "${DOCKER_PREFERENCES}.bak"
        
        sed -i '' 's/"insecure-registries":\[/"insecure-registries":["localhost:${REGISTRY_PORT}",/' "$DOCKER_PREFERENCES"
        
        echo "Added localhost:$REGISTRY_PORT to insecure registries in Docker Desktop preferences."
    else
        echo "localhost:$REGISTRY_PORT is already in the list of insecure registries."
    fi

    echo "Local registry setup complete."
}

echo "Starting setup..."

install_homebrew

install_docker

install_docker_compose

install_kind

install_kubectl

create_kind_cluster

create_docker_local_registry

docker-compose up -d --build

echo "Setup complete. Jenkins is now running and configured."
echo "Access Jenkins at http://localhost:8080 . Login with username: admin and password: admin"
