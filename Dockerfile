FROM golang:1.21-alpine

# Install dependencies (basic utilities)
RUN apk add --no-cache bash git

# Set up workspace directory
WORKDIR /app
RUN mkdir -p /workspace/target /workspace/corpus

# Copy entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Set default environment variables
ENV TARGET_DIR=/workspace/target \
    CORPUS_DIR=/workspace/corpus \
    FUZZ_TIME=1m \
    GO_FUZZ_FLAGS="-v"

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]