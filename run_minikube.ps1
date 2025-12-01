$CustomImageTag = "custom-jen:1.0.0"
$Namespace = "cicd"
$ChartPath = "./jenkins-nexus-chart"
$ReleaseName = "cicd-release"

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build --no-cache -t $CustomImageTag .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed!"
    exit 1
}

# Load into Minikube
Write-Host "Loading image into Minikube..." -ForegroundColor Cyan
minikube image load $CustomImageTag

# Verify image
$images = minikube image ls | Select-String "custom-jen"
if (-not $images) {
    Write-Error "Image not found in Minikube!"
    exit 1
}
Write-Host "Image loaded successfully" -ForegroundColor Green

# Setup namespace
Write-Host "Setting up namespace..." -ForegroundColor Cyan
if (-not (kubectl get ns $Namespace --ignore-not-found)) {
    kubectl create namespace $Namespace
}

# Complete cleanup
Write-Host "Performing complete cleanup..." -ForegroundColor Yellow
helm uninstall $ReleaseName -n $Namespace 2>$null
Start-Sleep -Seconds 5

# Delete all resources including PVCs
kubectl delete all --all -n $Namespace --force --grace-period=0 2>$null
kubectl delete pvc --all -n $Namespace --force --grace-period=0 2>$null
Start-Sleep -Seconds 10

# Clean charts
Write-Host "Cleaning charts directory..." -ForegroundColor Cyan
Remove-Item -Path "$ChartPath/charts" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChartPath/Chart.lock" -Force -ErrorAction SilentlyContinue

# Download dependencies
Write-Host "Downloading Helm dependencies..." -ForegroundColor Cyan
helm dependency update $ChartPath

# Install
Write-Host "Installing Helm chart..." -ForegroundColor Cyan
helm install $ReleaseName $ChartPath -n $Namespace --set jenkins.controller.image="custom-jen" --set jenkins.controller.tag="1.0.0" --set jenkins.controller.imagePullPolicy="Never" --set jenkins.controller.adminUser="admin" --set jenkins.controller.adminPassword="admin123" --set jenkins.persistence.storageClass="standard" --set nexus-repository-manager.persistence.storageClass="standard" --wait --timeout 10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    kubectl get pods -n $Namespace
    kubectl get pvc -n $Namespace
    exit 1
}

# Wait for pods
Write-Host "Waiting for pods to be ready..." -ForegroundColor Cyan
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=jenkins -n $Namespace --timeout=300s

# Port forwarding
Write-Host "Setting up port forwarding..." -ForegroundColor Cyan

Start-Job -ScriptBlock {
    param($service, $namespace)
    kubectl port-forward "svc/$service" 8080:8080 -n $namespace
} -ArgumentList "$ReleaseName-jenkins", $Namespace | Out-Null

Start-Sleep -Seconds 2

Start-Job -ScriptBlock {
    param($service, $namespace)
    kubectl port-forward "svc/$service" 8081:8081 -n $namespace
} -ArgumentList "$ReleaseName-nexus-repository-manager", $Namespace | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Jenkins: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Nexus:   http://localhost:8081" -ForegroundColor Cyan
Write-Host ""
Write-Host "Jenkins Credentials:" -ForegroundColor Yellow
Write-Host "  Username: admin" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "To stop port forwarding, run: Get-Job | Stop-Job" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Green
Write-Host ""