# ---- Stage 1: build du web avec Dart ≥3.7.2 ----
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# (Optionnel) Vérifier la version de Flutter/Dart
# RUN flutter --version

# 1. Copier les déclarations de dépendances
COPY pubspec.* ./

# 2. Récupération des dépendances
RUN flutter pub get

# 3. Copier le reste du code
COPY . .

# 4. Build en release pour le web
RUN flutter build web --release

# ---- Stage 2: serveur Nginx ----
FROM nginx:alpine

# Copier la build Flutter dans le dossier web de Nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

# Démarrage de Nginx en avant-plan
CMD ["nginx", "-g", "daemon off;"]
