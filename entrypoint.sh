#!/bin/bash
# Execute one fuzzing cycle, assuming repositories are already available locally

set -e  # Exit on any error

# Load configuration
TARGET_DIR=${TARGET_DIR:-"/workspace/target"}
CORPUS_DIR=${CORPUS_DIR:-"/workspace/corpus"}
FUZZ_TIME=${FUZZ_TIME:-"1m"}
GO_FUZZ_FLAGS=${GO_FUZZ_FLAGS:-"-v"}

echo "Starting fuzzing cycle at $(date)"
echo "Target directory: $TARGET_DIR"
echo "Corpus directory: $CORPUS_DIR"
echo "Fuzz duration: $FUZZ_TIME"

# Validate directories exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory not found: $TARGET_DIR"
    exit 1
fi

if [ ! -d "$CORPUS_DIR" ]; then
    echo "Error: Corpus directory not found: $CORPUS_DIR"
    mkdir -p "$CORPUS_DIR"
    echo "Created empty corpus directory"
fi

# Change to target directory
cd "$TARGET_DIR"

# Find all Go packages with fuzz tests
echo "Finding packages with fuzz tests..."
PACKAGES=$(go list ./... 2>/dev/null)

# Display the packages found
echo "Found packages:"
for pkg in $PACKAGES; do
    echo " - $pkg"
done

if [ -z "$PACKAGES" ]; then
    echo "No packages found"
    exit 0
fi

# Track if we found any fuzz tests
FOUND_FUZZ_TESTS=0

# Run fuzzing for each package
for pkg in $PACKAGES; do
    # Find fuzz test functions in this package
    FUZZ_TESTS=$(go test -list "^Fuzz" $pkg 2>/dev/null | grep "^Fuzz" || echo "")

    if [ -z "$FUZZ_TESTS" ]; then
        # No fuzz tests in this package, skip it
        continue
    fi

    echo "Processing package: $pkg"
    echo "Found fuzz tests: $FUZZ_TESTS"
    FOUND_FUZZ_TESTS=1

    # For each fuzz test in the package
    for test in $FUZZ_TESTS; do
        echo "Running fuzz test: $test in package $pkg for $FUZZ_TIME..."

        # Get the package directory
        pkg_dir=$(go list -f '{{.Dir}}' $pkg)

        # Change to the package directory to run the test
        pushd "$pkg_dir" > /dev/null

        # Run the fuzz test (use ^ and $ to match exact test name)
        go test -fuzz="^$test\$" -fuzztime=$FUZZ_TIME $GO_FUZZ_FLAGS || true

        # Return to target directory
        popd > /dev/null
    done
done

if [ $FOUND_FUZZ_TESTS -eq 0 ]; then
    echo "No fuzz tests found in any package"
    exit 0
fi

# Collect corpus
echo "Collecting corpus files..."

# Find all testdata/fuzz directories with corpus files
find . -type d -path "*/testdata/fuzz/*" | while read -r fuzz_dir; do
    # Extract the fuzz test name (last component of the path)
    fuzz_test=$(basename "$fuzz_dir")

    echo "Found corpus for: $fuzz_test"

    # Create corresponding directory in corpus repo
    mkdir -p "$CORPUS_DIR/testdata/fuzz/$fuzz_test"

    # Copy corpus files (if any exist)
    if [ -n "$(ls -A $fuzz_dir 2>/dev/null)" ]; then
        echo "Copying corpus for $fuzz_test"
        cp -r "$fuzz_dir"/* "$CORPUS_DIR/testdata/fuzz/$fuzz_test/" 2>/dev/null || true
    fi
done

# Create metadata file with timestamp
cat > "$CORPUS_DIR/.fuzzer-metadata.json" <<EOF
{
    "last_run": "$(date -Iseconds)",
    "target_dir": "$TARGET_DIR",
    "fuzz_time": "$FUZZ_TIME"
}
EOF

echo "Fuzzing cycle completed successfully at $(date)"
exit 0