set -e

VERSION=${1:-latest}
NAMESPACE="artfans"

echo "🚀 Deploying version: $VERSION"

echo "📋 Applying Kubernetes configurations..."
kubectl apply -f kubernetes/namespace.yml
kubectl apply -f kubernetes/configmap.yml
kubectl apply -f kubernetes/storage/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/frontend/

if [ "$VERSION" != "latest" ]; then
    PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
    echo "🔄 Updating images to version $VERSION..."
    kubectl set image deployment/artfans-api api=europe-docker.pkg.dev/${PROJECT_ID}/artfans/artfans-api:${VERSION} -n ${NAMESPACE}
    kubectl set image deployment/artfans-web web=europe-docker.pkg.dev/${PROJECT_ID}/artfans/artfans-web:${VERSION} -n ${NAMESPACE}
fi

echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/artfans-api -n ${NAMESPACE}
kubectl rollout status deployment/artfans-web -n ${NAMESPACE}

echo "✅ Deployment completed!"
kubectl get pods -n ${NAMESPACE}