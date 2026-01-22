# Kubernetes Playground

Practice deploying a Vite React app to Kubernetes with Helm charts.

## Quick Start

### Deploy Everything

```bash
./deploy.sh
```

This script will:
- Build the Docker image using minikube's Docker daemon
- Install or upgrade the Helm chart
- Wait for pods to be ready
- Show you how to access the app

### Manual Deployment

If you prefer to do it step by step:

```bash
# 1. Build Docker image
eval $(minikube docker-env)
docker build -t vite-app:latest .

# 2. Deploy with Helm
helm install vite-app ./helm/vite-app
# Or upgrade if already installed:
helm upgrade vite-app ./helm/vite-app

# 3. Access the app
minikube service vite-app
```

## Update App

Just run the deploy script again - it will rebuild and upgrade automatically:

```bash
./deploy.sh
```

Or manually:
```bash
eval $(minikube docker-env)
docker build -t vite-app:latest .
helm upgrade vite-app ./helm/vite-app
```

## Useful Commands

```bash
# Check status
kubectl get pods
kubectl get svc

# View logs
kubectl logs -l app=vite-app

# Uninstall
helm uninstall vite-app
```

## Project Structure

```
k8s-playground/
├── app/                    # Vite React app
├── helm/vite-app/          # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
├── Dockerfile
├── nginx.conf
└── deploy.sh               # Deployment script
```
