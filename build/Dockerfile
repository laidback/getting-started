FROM golang:1.12.9-alpine3.10 as builder
COPY main.go .
# `skaffold debug` sets SKAFFOLD_GO_GCFLAGS to disable compiler optimizations
ARG SKAFFOLD_GO_GCFLAGS
RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /app main.go

# Now copy it into our base image.
FROM alpine:3.10
ENV GOTRACEBACK=single
EXPOSE 8080/tcp
COPY api/petstore.yaml /petstore.yaml
COPY --from=builder /app .
CMD [ "/app" ]
