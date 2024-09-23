#!/bin/bash

set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_docker() {
    echo "Installing Docker..."
    if ! command_exists docker; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        echo "Docker installed. You may need to log out and back in for group changes to take effect."
    else
        echo "Docker is already installed."
    fi
}

install_docker_compose() {
    echo "Installing Docker Compose..."
    if ! command_exists docker-compose; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed."
    fi
}

install_kind() {
    echo "Installing Kind..."
    if ! command_exists kind; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    else
        echo "Kind is already installed."
    fi
}

install_kubectl() {
    echo "Installing kubectl..."
    if ! command_exists kubectl; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
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
        echo "Docker is not installed. Please install Docker first."
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

    DOCKER_CONFIG_FILE="/etc/docker/daemon.json"
    if [ ! -f "$DOCKER_CONFIG_FILE" ]; then
        echo "{}" | sudo tee $DOCKER_CONFIG_FILE
    fi

    if ! grep -q "insecure-registries" "$DOCKER_CONFIG_FILE"; then
        sudo sed -i '$ s/}/,"insecure-registries":["localhost:5555"]}/' $DOCKER_CONFIG_FILE
        echo "Added localhost:5555 to insecure registries in Docker daemon config."
        echo "Please restart the Docker daemon for changes to take effect."
        echo "You can do this by running: sudo systemctl restart docker"
    else
        echo "localhost:5555 is already in the list of insecure registries."
    fi

    echo "Local registry setup complete."
}

echo "Starting setup..."

install_docker

install_docker_compose

install_kind

install_kubectl

create_kind_cluster

create_docker_local_registry

docker-compose up -d --build

echo "Setup complete. Jenkins is now running and configured."
echo "Access Jenkins at http://localhost:8080 . Login with username: admin and password: admin"
