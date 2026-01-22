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

# Fetch OpenAPI spec from backend for frontend type generation
echo "📝 Fetching OpenAPI spec from backend..."
if command -v curl &> /dev/null && command -v kubectl &> /dev/null; then
    echo "⏳ Waiting for backend to be accessible..."
    
    # Use kubectl port-forward to access backend via localhost (more reliable)
    # Use a random port to avoid conflicts
    PORT_FORWARD_PORT=30001
    # Start port-forward in background
    kubectl port-forward svc/backend ${PORT_FORWARD_PORT}:3000 > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to establish (check if process is still running)
    sleep 3
    if ! kill -0 $PORT_FORWARD_PID 2>/dev/null; then
        echo "⚠️  Port-forward failed to start, trying alternative method..."
        kill $PORT_FORWARD_PID 2>/dev/null || true
        # Fallback: try minikube service with timeout
        BACKEND_URL=$(timeout 10 minikube service backend --url 2>/dev/null | head -1 || echo "")
        if [ -n "$BACKEND_URL" ]; then
            if curl -s -f "${BACKEND_URL}/openapi" > openapi.json 2>/dev/null; then
                echo "✅ OpenAPI spec fetched successfully via minikube service"
                PORT_FORWARD_PID=""
            fi
        fi
    fi
    
    # Wait up to 60 seconds for backend to respond
    MAX_ATTEMPTS=30
    ATTEMPT=0
    SUCCESS=false
    
    if [ -n "$PORT_FORWARD_PID" ] && kill -0 $PORT_FORWARD_PID 2>/dev/null; then
        while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
            if curl -s -f "http://localhost:${PORT_FORWARD_PORT}/health" > /dev/null 2>&1; then
                echo "✅ Backend is accessible, fetching OpenAPI spec..."
                if curl -s -f "http://localhost:${PORT_FORWARD_PORT}/openapi" > openapi.json 2>/dev/null; then
                    echo "✅ OpenAPI spec fetched successfully"
                    SUCCESS=true
                    break
                else
                    echo "⚠️  Backend accessible but OpenAPI endpoint not available"
                    break
                fi
            fi
            ATTEMPT=$((ATTEMPT + 1))
            if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
                sleep 2
            fi
        done
        
        # Clean up port-forward
        kill $PORT_FORWARD_PID 2>/dev/null || true
        wait $PORT_FORWARD_PID 2>/dev/null || true
    fi
    
    if [ "$SUCCESS" = false ]; then
        echo "⚠️  Backend not accessible after waiting, skipping OpenAPI spec fetch"
        echo "   Frontend build will generate types from existing openapi.json or localhost:3000"
    fi
    
    if [ ! -f "openapi.json" ]; then
        echo "   Frontend build will generate types from existing openapi.json or localhost:3000"
    fi
else
    echo "⚠️  Required tools not found, skipping OpenAPI spec fetch"
    echo "   Frontend build will generate types from existing openapi.json or localhost:3000"
fi

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
