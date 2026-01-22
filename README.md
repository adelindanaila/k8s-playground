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

## PostgreSQL

### Deploy PostgreSQL

```bash
./deploy-postgres.sh
```

This script will:
- Add Bitnami Helm repository
- Install PostgreSQL with minikube-optimized settings
- Show connection information and credentials

### Access PostgreSQL

**From within the cluster:**
- Host: `postgresql`
- Port: `5432`
- Username: `postgres`
- Password: (shown after deployment, or get it with command below)
- Database: `postgres`

**From local machine:**
```bash
# Port forward
kubectl port-forward svc/postgresql 5432:5432

# Then connect to localhost:5432
```

**Connect via psql:**
```bash
kubectl run -it --rm psql --image=postgres:alpine --restart=Never -- \
  psql -h postgresql -U postgres -d postgres
```

### Useful PostgreSQL Commands

```bash
# Get password
kubectl get secret postgresql -o jsonpath="{.data.postgres-password}" | base64 -d

# View logs
kubectl logs -l app.kubernetes.io/name=postgresql

# Check status
kubectl get pods -l app.kubernetes.io/name=postgresql

# Uninstall
helm uninstall postgresql
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
├── helm/
│   ├── vite-app/           # Vite app Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── configmap.yaml
│   └── postgresql-values.yaml  # PostgreSQL configuration
├── Dockerfile
├── nginx.conf
├── deploy.sh               # Vite app deployment script
└── deploy-postgres.sh      # PostgreSQL deployment script
```
