#!/bin/bash
set -e

echo "🔧 Configuration du déploiement ArtFans sur GKE"

NAMESPACE="artfans"
PROJECT_ID="pure-karma-466322-v8"

echo "1️⃣ Mise à jour du secret DATABASE_URL..."
DATABASE_URL="postgres://artfans:kBF%26bv%3BdpaP7%5EqD7@127.0.0.1:5432/artfans_dev?sslmode=disable"
DATABASE_URL_BASE64=$(echo -n "$DATABASE_URL" | base64)
kubectl patch secret artfans-backend-secrets -n $NAMESPACE --type='json' \
  -p='[{"op": "replace", "path": "/data/DATABASE_URL", "value": "'$DATABASE_URL_BASE64'"}]'

echo "2️⃣ Configuration des permissions Cloud SQL..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client" || echo "Permissions déjà existantes"

echo "3️⃣ Vérification de la base de données..."
gcloud sql databases list --instance=artfans-pg --project=$PROJECT_ID | grep artfans_dev || \
  gcloud sql databases create artfans_dev --instance=artfans-pg --project=$PROJECT_ID

echo "4️⃣ Application des deployments..."
kubectl apply -f kubernetes/backend/deployment.yml
kubectl apply -f kubernetes/frontend/deployment.yml

echo "5️⃣ Suppression des anciens pods..."
kubectl delete pods --all -n $NAMESPACE --force --grace-period=0

echo "6️⃣ Surveillance du démarrage..."
kubectl get pods -n $NAMESPACE -w