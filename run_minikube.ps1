# PowerShell script for Windows Minikube deployment

$CustomImageTag = "custom-jen:latest"
$Namespace = "cicd"
$ChartPath = "./jenkins-nexus-chart"
$ReleaseName = "cicd-release"

Write-Host "Building custom Jenkins image: $CustomImageTag..."
docker build -t $CustomImageTag .

Write-Host "Loading image into Minikube..."
minikube image load $CustomImageTag

# CRITICAL FIX 1: Create the target namespace
Write-Host "Creating namespace $Namespace..."
# Logic to check if namespace exists and create it if not.
if (-not (kubectl get ns $Namespace --ignore-not-found)) {
    kubectl create namespace $Namespace
} else {
    Write-Host "Namespace $Namespace already exists. Continuing..."
}

# NEW FIX: Wait for the namespace to be ready before proceeding to helm install
Write-Host "Waiting for namespace $Namespace to be active..."
$i = 0
$maxAttempts = 30
while ($i -lt $maxAttempts) {
    # Check if the namespace exists and is active
    $status = kubectl get ns $Namespace -o jsonpath='{.status.phase}'
    if ($status -eq "Active") {
        Write-Host "Namespace $Namespace is Active. Continuing deployment."
        break
    }
    Write-Host "Namespace not ready yet. Waiting 1 second..."
    Start-Sleep -Seconds 1
    $i++
}

if ($i -eq $maxAttempts) {
    Write-Error "Timeout waiting for namespace $Namespace to become Active."
    exit 1
}

Write-Host "Fetching Helm chart dependencies..."
helm dependency build $ChartPath

Write-Host "Installing Helm chart $ReleaseName into namespace $Namespace..."
# CRITICAL FIX 2: Ensure -n $Namespace is included here!
helm install $ReleaseName $ChartPath -n $Namespace 

Write-Host "Port-forwarding Jenkins and Nexus to localhost..."
# CRITICAL FIX 3: Use Start-Job for background tasks, and ensure -n $Namespace is included
Start-Job -ScriptBlock { kubectl port-forward svc/jenkins 8080:8080 -n $Namespace }
Start-Job -ScriptBlock { kubectl port-forward svc/nexus-repository-manager 8081:8081 -n $Namespace }

Write-Host "Jenkins available at http://localhost:8080"
Write-Host "Nexus available at http://localhost:8081"