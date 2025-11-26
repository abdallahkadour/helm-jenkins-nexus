#!/bin/bash
set -e

# --- Configuration ---

CUSTOM_IMAGE_TAG="custom-jen:latest"
NAMESPACE="cicd"
CHART_PATH="./jenkins-nexus-chart"
RELEASE_NAME="cicd-release"

echo "Building custom Jenkins image: $CUSTOM_IMAGE_TAG..."
docker build -t $CUSTOM_IMAGE_TAG .

echo "Loading image into Minikube..."
minikube image load $CUSTOM_IMAGE_TAG

echo "Creating namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists or could not be created."

echo "Fetching Helm chart dependencies..."
helm dependency build $CHART_PATH

echo "Installing Helm chart $RELEASE_NAME into namespace $NAMESPACE..."
helm install $RELEASE_NAME $CHART_PATH -n $NAMESPACE

echo "Port-forwarding Jenkins and Nexus to localhost..."
# Using the correct namespace for port-forwarding
kubectl port-forward svc/jenkins 8080:8080 -n $NAMESPACE &
kubectl port-forward svc/nexus-repository-manager 8081:8081 -n $NAMESPACE &

echo "Jenkins available at http://localhost:8080"
echo "Nexus available at http://localhost:8081"