#!/bin/sh
set -e

echo "▶ Exécution des migrations (initdb)…"
./initdb

echo "▶ Démarrage de l’API (artfans-api)…"
exec ./artfans-api
