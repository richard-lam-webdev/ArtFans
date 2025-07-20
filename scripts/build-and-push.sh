

set -e

PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
REGISTRY_URL="europe-docker.pkg.dev"
VERSION=${1:-$(git rev-parse --short HEAD)}

echo "🔨 Building images with version: $VERSION"

cd backend
docker build -t ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-api:${VERSION} .
docker build -t ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-api:latest .
cd ..

cd frontend
flutter build web --release --web-renderer html
docker build -t ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-web:${VERSION} .
docker build -t ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-web:latest .
cd ..

echo "📤 Pushing images..."
docker push ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-api:${VERSION}
docker push ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-api:latest
docker push ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-web:${VERSION}
docker push ${REGISTRY_URL}/${PROJECT_ID}/artfans/artfans-web:latest

echo "✅ Build and push completed!"