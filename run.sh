#!/bin/bash
# run.sh - Start Angry-Fuzzer with configurable options

# Default values
TARGET_REPO=""
CORPUS_REPO=""
FUZZ_TIME="30s"
TEMP_DIR="/tmp/angry-fuzzer"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --target)
        TARGET_REPO="$2"
        shift 2
        ;;
    --corpus)
        CORPUS_REPO="$2"
        shift 2
        ;;
    --time)
        FUZZ_TIME="$2"
        shift 2
        ;;
    --temp)
        TEMP_DIR="$2"
        shift 2
        ;;
    --help)
        echo "Usage: ./run.sh [options]"
        echo ""
        echo "Options:"
        echo "  --target URL     Target repository URL (required)"
        echo "  --corpus URL     Corpus repository URL"
        echo "  --time DURATION  Fuzzing duration per test (default: 5m)"
        echo "  --temp DIR       Temporary directory (default: /tmp/angry-fuzzer)"
        echo "  --help           Show this help message"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help to see available options"
        exit 1
        ;;
    esac
done

# Validate required parameters
if [ -z "$TARGET_REPO" ]; then
    echo "Error: Target repository URL is required"
    echo "Use --help to see available options"
    exit 1
fi

# Export variables for docker-compose
export TARGET_REPO
export CORPUS_REPO
export FUZZ_TIME
export TEMP_DIR

# Create temporary directory
mkdir -p "$TEMP_DIR"

echo "Starting angry-fuzzer with the following configuration:"
echo "Target repository: $TARGET_REPO"
echo "Corpus repository: ${CORPUS_REPO:-'None (using empty corpus)'}"
echo "Fuzz duration: $FUZZ_TIME"
echo "Temporary directory: $TEMP_DIR"
echo ""

# Start the controller
docker compose build
docker compose up controller
