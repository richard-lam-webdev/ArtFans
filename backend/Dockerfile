FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server/main.go


FROM alpine:3.18
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/main .

RUN mkdir -p /uploads && \
    chmod +x main && \
    adduser -D -u 1000 appuser && \
    chown -R appuser:appuser /app /uploads

USER appuser

EXPOSE 8080

CMD ["./main"]