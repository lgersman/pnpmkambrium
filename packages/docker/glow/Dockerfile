# syntax=docker/dockerfile:1.4

FROM golang:1.17-bullseye as build

# RUN go install github.com/charmbracelet/gum@latest
RUN CGO_ENABLED=0 go install github.com/charmbracelet/glow@latest

# FROM gcr.io/distroless/base-debian11
FROM gcr.io/distroless/static-debian11

COPY --from=build /go/bin/glow /bin/

ENTRYPOINT ["/bin/glow"]

