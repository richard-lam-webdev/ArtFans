#!/bin/sh
set -e
echo "▶ Lancement des migrations…"
./initdb
echo "▶ Démarrage de l’API…"
exec ./onlyart-api
