FROM golang:1.24-alpine

# Install dependencies
RUN apk add --no-cache bash git

# Set up working directory
WORKDIR /app

# Copy worker script
COPY ./entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]