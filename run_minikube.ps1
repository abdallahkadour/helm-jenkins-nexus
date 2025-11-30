$CustomImageTag = "custom-jen:1.0.0"
$Namespace = "cicd2"
$ChartPath = "./jenkins-nexus-chart"
$ReleaseName = "cicd-release"

# ----------------------------
# Build Docker image
# ----------------------------
Write-Host "Building Docker image: $CustomImageTag..."
docker build --no-cache -t $CustomImageTag .

# ----------------------------
# Load image into Minikube directly
# ----------------------------
Write-Host "Loading image into Minikube..."
minikube image load $CustomImageTag

# Set Helm image values for Minikube
$HelmImageRepository = $CustomImageTag
$HelmPullPolicy = "Never"

# ----------------------------
# Create namespace if it doesn't exist
# ----------------------------
if (-not (kubectl get ns $Namespace --ignore-not-found)) {
    kubectl create namespace $Namespace
}

# Wait until namespace is active
$i = 0; $maxAttempts = 30
while ($i -lt $maxAttempts) {
    $status = kubectl get ns $Namespace -o jsonpath='{.status.phase}'
    if ($status -eq "Active") { break }
    Start-Sleep -Seconds 1
    $i++
}
if ($i -eq $maxAttempts) { Write-Error "Namespace not active"; exit 1 }

# ----------------------------
# Helm dependencies
# ----------------------------
helm dependency build $ChartPath

# ----------------------------
# Install Helm chart using Minikube image
# ----------------------------
helm upgrade --install $ReleaseName $ChartPath -n $Namespace `
  --set jenkins.controller.image=$HelmImageRepository `
  --set jenkins.controller.tag=1.0.0 `
  --set jenkins.controller.pullPolicy=$HelmPullPolicy

# Wait for Jenkins pods to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=$ReleaseName -n $Namespace --timeout=600s

# ----------------------------
# Port-forward Jenkins & Nexus
# ----------------------------
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/$ReleaseName-jenkins 8080:8080 -n $Namespace" -Wait:$false
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/$ReleaseName-nexus-repository-manager 8081:8081 -n $Namespace" -Wait:$false

Write-Host "Jenkins: http://localhost:8080"
Write-Host "Nexus: http://localhost:8081"
