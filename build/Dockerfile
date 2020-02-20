FROM golang:1.13 as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o . ./...

FROM alpine
RUN adduser -S -D -H -h /app appuser
USER appuser
COPY --from=builder /app /app/
COPY --from=builder /app/static /app/static/
COPY --from=builder /app/data /app/data/
COPY --from=builder /app/migrations /app/migrations/
COPY --from=builder /app/templates /app/templates/

WORKDIR /app
CMD ["./wanikanitools-golang"]
