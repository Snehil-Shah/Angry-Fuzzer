#!/bin/bash
# Worker script for fuzzing a specific target

set +e

# Load configuration
TARGET_DIR=${TARGET_DIR:-"/tmp/angry-fuzzer/target"}
CORPUS_DIR=${CORPUS_DIR:-"/tmp/angry-fuzzer/corpus/"}
FUZZ_TIME=${FUZZ_TIME:-"5m"}
GO_FUZZ_FLAGS=${GO_FUZZ_FLAGS:-"-v"}
PKG_NAME=${PKG_NAME:-""}
PKG_RELATIVE_PATH=${PKG_RELATIVE_PATH:-""}
FUZZ_TARGET=${FUZZ_TARGET:-""}

echo "Starting worker with configuration:"
echo "TARGET_DIR: $TARGET_DIR"
echo "CORPUS_DIR: $CORPUS_DIR"
echo "FUZZ_TIME: $FUZZ_TIME"
echo "PKG_NAME: $PKG_NAME"
echo "PKG_RELATIVE_PATH: $PKG_RELATIVE_PATH"
echo "FUZZ_TARGET: $FUZZ_TARGET"

# Check if directories exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: Target directory does not exist: $TARGET_DIR"
    echo "Current directory: $(pwd)"
    echo "Listing root directory:"
    ls -la /
    echo "Listing workspace directory:"
    ls -la /workspace 2>/dev/null || echo "No /workspace directory"
    exit 1
fi

if [ ! -d "$CORPUS_DIR" ]; then
    echo "ERROR: Corpus directory does not exist: $CORPUS_DIR"
    echo "Creating corpus directory"
    mkdir -p "$CORPUS_DIR"
fi

if [ -z "$PKG_RELATIVE_PATH" ]; then
    echo "ERROR: No package relative path specified"
    exit 1
fi

if [ -z "$FUZZ_TARGET" ]; then
    echo "ERROR: No fuzz target function specified"
    exit 1
fi

echo "Worker starting at $(date) for package path: $PKG_RELATIVE_PATH, target: $FUZZ_TARGET"
echo "Target directory: $TARGET_DIR"
echo "Corpus directory: $CORPUS_DIR"
echo "Fuzz duration: $FUZZ_TIME"

# Construct package directory from relative path
pkg_dir="$TARGET_DIR/$PKG_RELATIVE_PATH"
echo "Package directory: $pkg_dir"

# Check if package directory exists
if [ ! -d "$pkg_dir" ]; then
    echo "ERROR: Package directory does not exist: $pkg_dir"
    exit 1
fi

# Change to the package directory
cd "$pkg_dir" || {
    echo "ERROR: Failed to change to package directory: $pkg_dir"
    exit 1
}

# Create a specific corpus directory for this target
target_corpus_dir="$CORPUS_DIR/$PKG_RELATIVE_PATH/$FUZZ_TARGET"
mkdir -p "$target_corpus_dir"

# Standard Go fuzz test corpus location
go_fuzz_dir="testdata/fuzz/$FUZZ_TARGET"
mkdir -p "$go_fuzz_dir"

# Verify that the specified target exists
if ! go test -list="^$FUZZ_TARGET\$" | grep -q "$FUZZ_TARGET"; then
    echo "ERROR: Fuzz target '$FUZZ_TARGET' not found in package at $PKG_RELATIVE_PATH"
    echo "Available targets:"
    go test -list=Fuzz.* || echo "No fuzz targets found"
    exit 1
fi

echo "Running fuzz target: $FUZZ_TARGET"
echo "Default corpus directory: $go_fuzz_dir"
echo "External corpus directory: $target_corpus_dir"

# Copy any existing corpus entries from our repository to the Go fuzz directory
if [ -d "$target_corpus_dir" ] && [ "$(ls -A "$target_corpus_dir" 2>/dev/null)" ]; then
    echo "Found existing corpus, copying to Go fuzz directory"
    cp -v "$target_corpus_dir"/* "$go_fuzz_dir/" 2>/dev/null || echo "No corpus files to copy"
fi

# Run the specific fuzz target
echo "Starting fuzzer at $(date)"
go test -fuzz="^$FUZZ_TARGET\$" -fuzztime="$FUZZ_TIME" $GO_FUZZ_FLAGS

exit_code=$?
echo "Fuzzer completed with exit code $exit_code at $(date)"

# After fuzzing completes, update our corpus directory with new entries
echo "Updating external corpus directory with new entries"
if [ -d "$go_fuzz_dir" ]; then
    # Ensure target directory exists
    mkdir -p "$target_corpus_dir"

    # Count corpus files before moving
    corpus_count=$(find "$go_fuzz_dir" -type f -maxdepth 1 | wc -l)

    if [ "$corpus_count" -gt 0 ]; then
        echo "Moving $corpus_count corpus files to external corpus directory"
        # Move all corpus files to our external corpus directory
        find "$go_fuzz_dir" -type f -maxdepth 1 -exec mv -v {} "$target_corpus_dir/" \;
    else
        echo "No corpus files found in $go_fuzz_dir"
    fi

    # Handle any crashers
    if [ -d "testdata/fuzz/$FUZZ_TARGET/crashers" ]; then
        mkdir -p "$target_corpus_dir/crashers"
        crasher_count=$(find "testdata/fuzz/$FUZZ_TARGET/crashers" -type f | wc -l)

        if [ "$crasher_count" -gt 0 ]; then
            echo "Moving $crasher_count crasher files to external crashers directory"
            find "testdata/fuzz/$FUZZ_TARGET/crashers" -type f -exec mv -v {} "$target_corpus_dir/crashers/" \;
        else
            echo "No crashers found"
        fi
    fi

    # Remove the testdata directory to clean up completely
    rm -rf "testdata"

    echo "Corpus directory updated successfully"
fi

echo "Worker completed successfully for target: $FUZZ_TARGET in package: $PKG_NAME at $(date)"