# ---- Stage 1 : build Flutter ----
FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN ls -l .env    
RUN cat .env      
RUN flutter build web --release

# ---- Stage 2 : Nginx ----
FROM nginx:alpine
COPY --from=flutter_builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
