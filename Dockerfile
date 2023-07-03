# Use the official Go image as the base image
FROM golang:1.20 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files
COPY server/go.mod server/go.sum ./server/
COPY client/go.mod ./client/

# Download the Go module dependencies
RUN cd server && go mod download
RUN cd client

# Copy the source code
COPY server/server.go ./server/
COPY client/client.go ./client/

# Force static build
ENV CGO_ENABLED=0

# Build the server binary
RUN cd server && go build -o gopher-squeeze

# Build the client binary
RUN cd client && go build -o gopher-squeeze

# Use a minimal base image for the final stage
FROM busybox:1-musl AS final
# FROM alpine:latest AS final

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled binaries from the builder stage and set executable permissions
COPY --from=builder /app/server/gopher-squeeze ./server/gopher-squeeze
COPY --from=builder /app/client/gopher-squeeze ./client/gopher-squeeze
RUN chmod +x ./server/gopher-squeeze ./client/gopher-squeeze

# Expose any necessary ports
EXPOSE 8000

# Create a non-root user
RUN adduser -D -u 1000 gopher

# Set the ownership and permissions for the files
RUN chown -R gopher:gopher .

# Switch to the non-root user
USER gopher
# USER 0

# Set default environment variables
ENV WEBHOOK_LISTEN=0.0.0.0:8000

# Set the entry point to run the server by default
ENTRYPOINT ["/app/server/gopher-squeeze"]
