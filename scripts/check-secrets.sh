echo "=== Vérification des secrets ArtFans ==="

echo -n "Namespace artfans: "
kubectl get namespace artfans &>/dev/null && echo "✓ OK" || echo "✗ MANQUANT"

echo -n "Secret artfans-backend-secrets: "
kubectl get secret artfans-backend-secrets -n artfans &>/dev/null && echo "✓ OK" || echo "✗ MANQUANT"

echo -n "Secret gcs-credentials: "
kubectl get secret gcs-credentials -n artfans &>/dev/null && echo "✓ OK" || echo "✗ MANQUANT"

echo ""
echo "Clés dans artfans-backend-secrets:"
kubectl get secret artfans-backend-secrets -n artfans -o jsonpath="{.data}" | jq -r 'keys[]' 2>/dev/null || echo "Erreur lors de la lecture"