# === Build Stage ===
FROM golang:1.23-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Compile initdb
RUN CGO_ENABLED=0 GOOS=linux go build -o initdb ./cmd/initdb
# Compile API server
RUN CGO_ENABLED=0 GOOS=linux go build -o onlyart-api ./cmd/server

# === Runtime Stage ===
FROM alpine:3.18
RUN apk add --no-cache ca-certificates
WORKDIR /app

COPY --from=builder /src/initdb ./
COPY --from=builder /src/onlyart-api ./

COPY entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]
