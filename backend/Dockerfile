# 1) builder
FROM golang:1.20-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git ca-certificates

# Copier module et dépendances Go
COPY go.mod go.sum ./
RUN go mod download

# Copier tout le code Go
COPY . .

# Compiler le binaire
RUN CGO_ENABLED=0 GOOS=linux go build -o initdb ./cmd/initdb

# 2) runtime
FROM alpine:3.18
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /src/initdb .
ENV DATABASE_URL=${DATABASE_URL}
ENTRYPOINT ["./initdb"]
