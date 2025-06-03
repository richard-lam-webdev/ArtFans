# === Build Stage ===
FROM golang:1.24-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o initdb ./cmd/initdb
RUN CGO_ENABLED=0 GOOS=linux go build -o artfans-api ./cmd/server

# === Runtime Stage ===
FROM alpine:3.18

RUN apk --no-cache add ca-certificates curl
WORKDIR /app

COPY --from=builder /src/initdb ./
COPY --from=builder /src/artfans-api ./

COPY entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
