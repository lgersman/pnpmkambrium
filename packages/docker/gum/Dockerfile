# syntax=docker/dockerfile:1.4

FROM golang:1.21-bookworm as build

# RUN go install github.com/charmbracelet/gum@latest
RUN CGO_ENABLED=0 go install github.com/charmbracelet/gum@latest

# FROM gcr.io/distroless/base-debian12
FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/gum /bin/

ENTRYPOINT ["/bin/gum"]

