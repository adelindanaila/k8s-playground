#!/bin/bash

set -e

echo "🚀 Deploying Vite app to Kubernetes..."

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Use minikube's Docker daemon
echo "📦 Setting up Docker environment..."
eval $(minikube docker-env)

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -f app/Dockerfile -t vite-app:latest .

# Check if Helm release exists
if helm list -q | grep -q "^vite-app$"; then
    echo "🔄 Upgrading existing Helm release..."
    UPGRADE_OUTPUT=$(helm upgrade vite-app ./helm/vite-app 2>&1) || true
    if echo "$UPGRADE_OUTPUT" | grep -q "field is immutable"; then
        echo "⚠️  Upgrade failed due to immutable fields. Reinstalling..."
        helm uninstall vite-app
        echo "✨ Installing Helm release..."
        helm install vite-app ./helm/vite-app
    else
        echo "🔄 Forcing pod restart to pick up new image..."
        kubectl rollout restart deployment/vite-app
    fi
else
    echo "✨ Installing new Helm release..."
    helm install vite-app ./helm/vite-app
fi

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=vite-app --timeout=60s || true

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods -l app=vite-app
echo ""
echo "🌐 Access your app:"
echo "   minikube service vite-app"
echo ""
echo "Or get the URL:"
minikube service vite-app --url 2>/dev/null || echo "   (Service may still be starting)"