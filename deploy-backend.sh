#!/bin/bash

set -e

echo "🚀 Deploying Hono backend to Kubernetes..."

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Check if PostgreSQL is deployed (needed for backend)
if ! helm list -q | grep -q "^postgresql$"; then
    echo "⚠️  PostgreSQL is not deployed. Deploy it first with: ./deploy-postgres.sh"
    echo "   Continuing anyway, but backend will fail until PostgreSQL is available..."
fi

# Use minikube's Docker daemon
echo "📦 Setting up Docker environment..."
eval $(minikube docker-env)

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -f backend/Dockerfile -t backend:latest .

# Check if Helm release exists
if helm list -q | grep -q "^backend$"; then
    echo "🔄 Upgrading existing Helm release..."
    UPGRADE_OUTPUT=$(helm upgrade backend ./helm/backend 2>&1) || true
    if echo "$UPGRADE_OUTPUT" | grep -q "field is immutable"; then
        echo "⚠️  Upgrade failed due to immutable fields. Reinstalling..."
        helm uninstall backend
        echo "✨ Installing Helm release..."
        helm install backend ./helm/backend
    else
        echo "🔄 Forcing pod restart to pick up new image..."
        kubectl rollout restart deployment/backend
    fi
else
    echo "✨ Installing new Helm release..."
    helm install backend ./helm/backend
fi

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s || true

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods -l app=backend
echo ""
echo "🌐 Access your backend:"
echo "   minikube service backend"
echo ""
echo "Or get the URL:"
minikube service backend --url 2>/dev/null || echo "   (Service may still be starting)"
echo ""
echo "💡 Test endpoints:"
echo "   curl http://\$(minikube service backend --url)/health"
echo "   curl http://\$(minikube service backend --url)/api/hello"
echo "   curl http://\$(minikube service backend --url)/api/db/test"
