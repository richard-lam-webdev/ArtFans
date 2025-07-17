# ---- Stage 1 : build Flutter Web ----
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder

# On déclare un ARG pour l'URL de l'API (à passer avec --build-arg)
ARG API_BASE_URL

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# ---- Stage 2 : Nginx pour servir le build ----
FROM nginx:alpine
COPY --from=flutter_builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
