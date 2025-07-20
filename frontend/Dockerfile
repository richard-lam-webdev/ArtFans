FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release


FROM nginx:alpine

RUN mkdir -p /var/cache/nginx/client_temp \
 && chown -R nginx:nginx /var/cache/nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=flutter_builder /app/build/web /usr/share/nginx/html

RUN chown -R nginx:nginx /usr/share/nginx/html

USER nginx

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
