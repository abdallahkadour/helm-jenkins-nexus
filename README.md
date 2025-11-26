# helm-jenkins-nexus

## Android CI/CD Environment (Jenkins + Nexus) on Minikube

This repository contains the configuration files and scripts required to
quickly spin up a self-contained Continuous Integration (CI) and
Artifact Management environment on a local Minikube cluster.

This setup is specifically tailored for building Android/React Native
applications using a custom Jenkins image with pre-installed build
tools, and a Nexus Repository Manager configured for storing APK
artifacts.

## 🚀 Project Overview

The environment deploys two core services:

### **Jenkins CI Server**

-   Deployed using a custom Docker image (`custom-jen:latest`) which
    includes Node.js, npm, Gradle, and Android SDK command-line tools.
-   Configured to run the Android/React Native build pipeline.

### **Nexus Repository Manager**

Configured with repositories to support the build process: -
`npm-proxy`: Proxy for npm registry. - `gradle-proxy`: Proxy for
Maven/Gradle dependencies. - `apk-hosted`: Raw hosted repository for
storing final `.apk` artifacts.

## 🛠️ Prerequisites

Ensure the following are installed: - Minikube - Docker - kubectl - Helm
3+ - PowerShell or Bash

## ⚙️ Configuration Details

Deployment is managed using the `jenkins-nexus-chart` Helm chart. Below
are key configurations:

  -----------------------------------------------------------------------------------------
  Component           Setting                       Value                 Purpose
  ------------------- ----------------------------- --------------------- -----------------
  Jenkins Image       `controller.repository`,      `custom-jen:latest`   Uses pre-built
                      `controller.tag`                                    Jenkins image

  Jenkins Auth        `controller.adminUser`,       `admin`, `admin123`   Default
                      `controller.adminPassword`                          credentials

  Jenkins Plugins     `controller.installPlugins`   `false`               Prevents pulling
                                                                          plugins during
                                                                          deploy

  Persistence         Jenkins/Nexus                 `10Gi / 20Gi`         Ensures data is
                                                                          preserved

  Nexus Repo          `apk-hosted`                  `raw-hosted`          APK storage

  Ingress Hosts       Jenkins/Nexus                 `jenkins.local`,      Clean access
                                                    `nexus.local`         endpoints
  -----------------------------------------------------------------------------------------

## 🚀 Deployment Instructions

### **Step 1: Build & Load Custom Jenkins Image**

``` bash
docker build -t custom-jen:latest .
minikube image load custom-jen:latest
```

### **Step 2: Deploy Using Helm Chart**

Run the provided script:

#### Windows PowerShell:

``` powershell
.un_minikube.ps1
```

#### Linux/WSL (Bash):

``` bash
./run_minikube.sh
```

### **Step 3: Access Services**

Check pod status:

``` bash
kubectl get pods -n nexus-jenkins
```

Stop previous forwarding (PowerShell only):

``` powershell
Get-Job | Stop-Job -PassThru | Remove-Job
```

Start port-forwarding:

#### Jenkins

``` bash
kubectl port-forward svc/jenkins-nexus 8080:8080 -n nexus-jenkins
```

#### Nexus

``` bash
kubectl port-forward svc/jenkins-nexus-nexus-repository-manager 8081:8081 -n nexus-jenkins
```

### **Service URLs**

  Service   URL                     Credentials
  --------- ----------------------- ------------------
  Jenkins   http://localhost:8080   admin / admin123
  Nexus     http://localhost:8081   admin / admin123

------------------------------------------------------------------------

## 📦 CI/CD Pipeline (Jenkinsfile)

The Jenkinsfile performs the following:

  Stage                  Action
  ---------------------- -----------------------------
  Checkout               Clone repository
  Install Dependencies   `npm install`
  Build Android APK      `./gradlew assembleRelease`
  Archive APK            Store artifact in Jenkins
  Upload to Nexus        Upload APK via `curl`

Upload endpoint:

    http://nexus.local/repository/apk-hosted/app-release.apk
