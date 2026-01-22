#!/bin/bash

set -e

echo "🐘 Deploying PostgreSQL to Kubernetes..."

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "❌ Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Add Bitnami Helm repository if not already added
if ! helm repo list | grep -q bitnami; then
    echo "📦 Adding Bitnami Helm repository..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
else
    echo "📦 Bitnami repository already added, updating..."
    helm repo update
fi

# Check if PostgreSQL is already installed
if helm list -q | grep -q "^postgresql$"; then
    echo "🔄 PostgreSQL is already installed."
    echo "   To upgrade: helm upgrade postgresql bitnami/postgresql -f helm/postgresql-values.yaml"
    echo "   To uninstall: helm uninstall postgresql"
    exit 0
fi

# Install PostgreSQL
echo "✨ Installing PostgreSQL..."
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

# Get connection information
echo ""
echo "✅ PostgreSQL deployment complete!"
echo ""
echo "📊 Status:"
kubectl get pods -l app.kubernetes.io/name=postgresql
echo ""
echo "🔐 Connection Information:"
echo ""
POSTGRES_PASSWORD=$(kubectl get secret postgresql -o jsonpath="{.data.postgres-password}" 2>/dev/null | base64 -d || echo "not available yet")
if [ "$POSTGRES_PASSWORD" != "not available yet" ]; then
    echo "   Username: postgres"
    echo "   Password: $POSTGRES_PASSWORD"
    echo "   Host: postgresql (from within cluster)"
    echo "   Port: 5432"
    echo "   Database: postgres"
    echo ""
    echo "   Connection string:"
    echo "   postgresql://postgres:$POSTGRES_PASSWORD@postgresql:5432/postgres"
    echo ""
    echo "🌐 Access from local machine:"
    echo "   kubectl port-forward svc/postgresql 5432:5432"
    echo "   Then connect to: localhost:5432"
    echo ""
    echo "💡 Connect via psql:"
    echo "   kubectl run -it --rm psql --image=postgres:alpine --restart=Never -- \\"
    echo "     psql -h postgresql -U postgres -d postgres"
else
    echo "   (Credentials not available yet, check again in a moment)"
fi
