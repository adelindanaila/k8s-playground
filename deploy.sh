#!/bin/bash

set -e

echo "🚀 Deploying K8s Playground (Frontend + Backend + PostgreSQL if needed)..."

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Use minikube's Docker daemon
echo "📦 Setting up Docker environment..."
eval $(minikube docker-env)

# ============================================================================
# 1. Deploy PostgreSQL (only if not already running)
# ============================================================================
echo ""
echo "🐘 Checking PostgreSQL deployment..."

if helm list -q | grep -q "^postgresql$"; then
    echo "✅ PostgreSQL is already deployed. Skipping..."
else
    echo "📦 Deploying PostgreSQL..."
    
    # Add Bitnami Helm repository if not already added
    if ! helm repo list | grep -q bitnami; then
        echo "📦 Adding Bitnami Helm repository..."
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo update
    else
        echo "📦 Bitnami repository already added, updating..."
        helm repo update
    fi
    
    # Install PostgreSQL
    if [ -f "helm/postgresql-values.yaml" ]; then
        helm install postgresql bitnami/postgresql -f helm/postgresql-values.yaml
    else
        echo "⚠️  Using default values (helm/postgresql-values.yaml not found)"
        helm install postgresql bitnami/postgresql \
            --set auth.postgresPassword=postgres \
            --set primary.resourcesPreset=nano \
            --set primary.persistence.size=8Gi
    fi
    
    # Wait for PostgreSQL to be ready
    echo "⏳ Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=120s || true
    
    echo "✅ PostgreSQL deployed!"
fi

# ============================================================================
# 2. Deploy Backend
# ============================================================================
echo ""
echo "🔧 Deploying Hono backend..."

# Build the Docker image
echo "🔨 Building backend Docker image..."
docker build -f backend/Dockerfile -t backend:latest .

# Generate OpenAPI spec for frontend (if backend is accessible)
echo "📝 Generating OpenAPI spec..."
if command -v curl &> /dev/null; then
    # Try to get OpenAPI spec from running backend or generate a placeholder
    BACKEND_URL=$(minikube service backend --url 2>/dev/null | head -1) || BACKEND_URL="http://localhost:3000"
    if curl -s -f "${BACKEND_URL}/openapi" > openapi.json 2>/dev/null; then
        echo "✅ OpenAPI spec generated from running backend"
    else
        echo "⚠️  Backend not accessible, skipping OpenAPI spec generation"
        echo "   Frontend build will use existing types or generate from localhost:3000"
    fi
else
    echo "⚠️  curl not found, skipping OpenAPI spec generation"
fi

# Deploy backend with Helm
if helm list -q | grep -q "^backend$"; then
    echo "🔄 Upgrading existing backend Helm release..."
    UPGRADE_OUTPUT=$(helm upgrade backend ./helm/backend 2>&1) || true
    if echo "$UPGRADE_OUTPUT" | grep -q "field is immutable"; then
        echo "⚠️  Upgrade failed due to immutable fields. Reinstalling..."
        helm uninstall backend
        echo "✨ Installing backend Helm release..."
        helm install backend ./helm/backend
    else
        echo "🔄 Forcing pod restart to pick up new image..."
        kubectl rollout restart deployment/backend
    fi
else
    echo "✨ Installing new backend Helm release..."
    helm install backend ./helm/backend
fi

# Wait for backend pods to be ready
echo "⏳ Waiting for backend pods to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s || true

echo "✅ Backend deployed!"

# ============================================================================
# 3. Deploy Frontend
# ============================================================================
echo ""
echo "🎨 Deploying Vite frontend..."

# Build the Docker image
echo "🔨 Building frontend Docker image..."
docker build -f app/Dockerfile -t vite-app:latest .

# Deploy frontend with Helm
if helm list -q | grep -q "^vite-app$"; then
    echo "🔄 Upgrading existing frontend Helm release..."
    UPGRADE_OUTPUT=$(helm upgrade vite-app ./helm/vite-app 2>&1) || true
    if echo "$UPGRADE_OUTPUT" | grep -q "field is immutable"; then
        echo "⚠️  Upgrade failed due to immutable fields. Reinstalling..."
        helm uninstall vite-app
        echo "✨ Installing frontend Helm release..."
        helm install vite-app ./helm/vite-app
    else
        echo "🔄 Forcing pod restart to pick up new image..."
        kubectl rollout restart deployment/vite-app
    fi
else
    echo "✨ Installing new frontend Helm release..."
    helm install vite-app ./helm/vite-app
fi

# Wait for frontend pods to be ready
echo "⏳ Waiting for frontend pods to be ready..."
kubectl wait --for=condition=ready pod -l app=vite-app --timeout=60s || true

echo "✅ Frontend deployed!"

# ============================================================================
# 4. Show Status
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 Pod Status:"
echo ""
echo "PostgreSQL:"
kubectl get pods -l app.kubernetes.io/name=postgresql 2>/dev/null || echo "  (not deployed)"
echo ""
echo "Backend:"
kubectl get pods -l app=backend
echo ""
echo "Frontend:"
kubectl get pods -l app=vite-app
echo ""

echo "🌐 Access your application:"
echo ""
echo "  Frontend:"
echo "    minikube service vite-app"
echo ""
echo "  Backend:"
echo "    minikube service backend"
echo ""
echo "  Or get URLs:"
FRONTEND_URL=$(minikube service vite-app --url 2>/dev/null | head -1 || echo "  (starting...)")
BACKEND_URL=$(minikube service backend --url 2>/dev/null | head -1 || echo "  (starting...)")
echo "    Frontend: $FRONTEND_URL"
echo "    Backend: $BACKEND_URL"
echo ""

echo "💡 Useful commands:"
echo "    # View logs"
echo "    kubectl logs -l app=backend"
echo "    kubectl logs -l app=vite-app"
echo ""
echo "    # Check status"
echo "    kubectl get pods"
echo "    kubectl get svc"
echo ""
