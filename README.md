# Kubernetes Playground

Practice deploying a full-stack application (Vite React frontend + Hono backend + PostgreSQL) to Kubernetes with Helm charts.

## Quick Start

### Deploy Everything

```bash
./deploy.sh
```

This script will:
- Deploy PostgreSQL (only if not already running)
- Build and deploy the backend with latest changes
- Build and deploy the frontend with latest changes
- Wait for all pods to be ready
- Show you how to access all services

### Manual Deployment

If you prefer to do it step by step:

```bash
# 1. Build Docker image
eval $(minikube docker-env)
docker build -f app/Dockerfile -t vite-app:latest .

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
docker build -f app/Dockerfile -t vite-app:latest .
helm upgrade vite-app ./helm/vite-app
```

## PostgreSQL

### Deploy PostgreSQL

```bash
./scripts/deploy-postgres.sh
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

## Backend (Hono API)

### Deploy Backend

**Prerequisites:** PostgreSQL must be deployed first.

```bash
./scripts/deploy-backend.sh
```

This script will:
- Build the Docker image using minikube's Docker daemon
- Install or upgrade the Helm chart
- Wait for pods to be ready
- Show connection information

### Access Backend

**From within the cluster:**
- Service name: `backend`
- Port: `3000`

**From local machine:**
```bash
# Port forward
kubectl port-forward svc/backend 3000:3000

# Then access at http://localhost:3000
```

**Or use minikube service:**
```bash
minikube service backend
```

### API Endpoints

- `GET /` - API information
- `GET /health` - Health check (includes database connection status)
- `GET /api/hello` - Simple hello endpoint
- `GET /api/db/test` - Test database connection

**Test endpoints:**
```bash
# Get backend URL
BACKEND_URL=$(minikube service backend --url)

# Test endpoints
curl $BACKEND_URL/health
curl $BACKEND_URL/api/hello
curl $BACKEND_URL/api/db/test
```

### Backend Features

- **Stateless architecture** - Supports multiple replicas (default: 2)
- **PostgreSQL connection** - Connects to PostgreSQL using Kubernetes service DNS
- **Health checks** - Includes database connection verification
- **Connection pooling** - Efficient database connection management

### Useful Backend Commands

```bash
# View logs
kubectl logs -l app=backend

# View logs from specific pod
kubectl logs <pod-name>

# Check status
kubectl get pods -l app=backend

# Scale replicas
kubectl scale deployment backend --replicas=3

# Uninstall
helm uninstall backend
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
├── app/                    # Vite React app (frontend)
├── backend/                # Hono backend app
│   ├── src/
│   │   ├── index.ts        # Main server file
│   │   └── db.ts           # PostgreSQL connection module
│   ├── package.json
│   └── tsconfig.json
├── helm/
│   ├── vite-app/           # Frontend Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── configmap.yaml
│   ├── backend/            # Backend Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       └── service.yaml
│   └── postgresql-values.yaml  # PostgreSQL configuration
├── app/
│   └── Dockerfile          # Frontend Dockerfile
├── backend/
│   └── Dockerfile          # Backend Dockerfile
├── nginx.conf
├── deploy.sh               # Frontend deployment script
├── deploy.sh                 # Main deployment script (deploys everything)
└── scripts/
    ├── deploy-backend.sh     # Backend deployment script
    ├── deploy-frontend.sh    # Frontend deployment script
    └── deploy-postgres.sh    # PostgreSQL deployment script
```
