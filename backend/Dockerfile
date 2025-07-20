FROM golang:1.21-alpine AS builder

WORKDIR /app

# Dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server/main.go

# Final stage
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy binary
COPY --from=builder /app/main .

# Create uploads directory
RUN mkdir -p /uploads

# Non-root user
RUN adduser -D -u 1000 appuser
USER appuser

EXPOSE 8080

CMD ["./main"]