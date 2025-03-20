#!/bin/bash
# Controller script for orchestrating fuzzer workers

set -e

# Load configuration
TARGET_REPO=${TARGET_REPO:-""}
CORPUS_REPO=${CORPUS_REPO:-""}
TEMP_DIR=${TEMP_DIR:-"/tmp/angry-fuzzer"}
TARGET_DIR="$TEMP_DIR/target"
CORPUS_DIR="$TEMP_DIR/corpus"
FUZZ_TIME=${FUZZ_TIME:-"5m"}
WORKER_IMAGE=${WORKER_IMAGE:-"angry-fuzzer-worker:latest"}
NETWORK_NAME=${NETWORK_NAME:-"angry-fuzzer_fuzzing-network"}

echo "Fuzzing Controller starting at $(date)"
echo "Target repository: $TARGET_REPO"
echo "Corpus repository: $CORPUS_REPO"
echo "Working directory: $TEMP_DIR"
echo "Fuzz duration: $FUZZ_TIME"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Clone or update the target repository
if [ -z "$TARGET_REPO" ]; then
    echo "Error: No target repository specified"
    exit 1
fi

echo "Cloning target repository..."
git clone "$TARGET_REPO" "$TARGET_DIR"

# Clone or update the corpus repository
if [ -z "$CORPUS_REPO" ]; then
    echo "No corpus repository specified."
    exit 1
fi
echo "Cloning corpus repository..."
git clone "$CORPUS_REPO" "$CORPUS_DIR"

# Change to target directory
cd "$TARGET_DIR"

# Find all Go packages with potential fuzz tests (faster approach)
echo "Finding Go packages..."
ALL_PACKAGES=$(go list ./... 2>/dev/null || true)

# Create an array of all packages
readarray -t all_package_array <<< "$ALL_PACKAGES"
all_package_count=${#all_package_array[@]}

echo "Found $all_package_count total Go packages"

# Find potential fuzz test files more efficiently
echo "Searching for fuzz test files..."
# First, find all test files containing fuzz functions
FUZZ_TEST_FILES=$(find . -name "*_test.go" -exec grep -l "func Fuzz" {} \; 2>/dev/null || echo "")

# Then extract their directories without using xargs dirname
POTENTIAL_FUZZ_PACKAGES=""
if [ -n "$FUZZ_TEST_FILES" ]; then
    for file in $FUZZ_TEST_FILES; do
        # Get the directory containing this file
        dir=$(dirname "$file")
        POTENTIAL_FUZZ_PACKAGES="$POTENTIAL_FUZZ_PACKAGES$dir\n"
    done
    # Use sort and uniq to get unique directories
    POTENTIAL_FUZZ_PACKAGES=$(echo -e "$POTENTIAL_FUZZ_PACKAGES" | sort | uniq)
fi

FUZZ_PACKAGE_COUNT=$(echo "$POTENTIAL_FUZZ_PACKAGES" | grep -v '^$' | wc -l)
echo "Found $FUZZ_PACKAGE_COUNT potential packages with fuzz tests"

# Create a list of packages to process
packages=()
for pkg_dir in $POTENTIAL_FUZZ_PACKAGES; do
    # Convert directory to package name
    cd "$TARGET_DIR"
    pkg_name=$(cd "$pkg_dir" && go list 2>/dev/null)
    if [ ! -z "$pkg_name" ]; then
        packages+=("$pkg_name")
    fi
done

total_packages=${#packages[@]}
echo "Found $total_packages packages with fuzz tests"

# Clean up any existing worker containers from previous runs
echo "Cleaning up any existing worker containers..."
docker ps -a --filter "name=angry-fuzzer-worker-" -q | xargs -r docker rm -f

worker_containers=()

# Start a worker for each fuzz target in each package
echo "Finding and starting workers for all fuzz targets..."
for i in "${!packages[@]}"; do
    package="${packages[$i]}"
    echo "[$(date)] Finding fuzz targets in package: $package"

    # Get the package directory (absolute path)
    abs_pkg_dir=$(go list -f '{{.Dir}}' $package 2>/dev/null)

    if [ -z "$abs_pkg_dir" ]; then
        echo "[$(date)] WARNING: Could not determine directory for package: $package"
        continue
    fi

    # Extract the relative path by removing the target directory prefix
    rel_pkg_dir=${abs_pkg_dir#"$TARGET_DIR/"}

    echo "[$(date)] Package directory: $rel_pkg_dir"

    # Find all fuzz targets in this package
    cd "$TARGET_DIR/$rel_pkg_dir"
    fuzz_targets=$(go test -list=Fuzz.* 2>/dev/null | grep Fuzz || echo "")

    if [ -z "$fuzz_targets" ]; then
        echo "[$(date)] No fuzz targets found in package: $package"
        continue
    fi

    # Start a worker for each fuzz target
    while read -r fuzz_target; do
        if [ -z "$fuzz_target" ]; then
            continue
        fi
        worker_count=$((worker_count + 1))
        container_name="angry-fuzzer-worker-$worker_count-$(echo $rel_pkg_dir | tr '/' '-')-$(echo $fuzz_target | tr '[:upper:]' '[:lower:]')"

        echo "[$(date)] Starting worker $worker_count for target: $rel_pkg_dir:$fuzz_target"
        docker run -d \
            --name "$container_name" \
            --network "$NETWORK_NAME" \
            -v "$TARGET_DIR:$TARGET_DIR" \
            -v "$CORPUS_DIR:$CORPUS_DIR" \
            -e TARGET_DIR=$TARGET_DIR \
            -e CORPUS_DIR=$CORPUS_DIR \
            -e FUZZ_TIME="$FUZZ_TIME" \
            -e PKG_RELATIVE_PATH="$rel_pkg_dir" \
            -e PKG_NAME="$package" \
            -e FUZZ_TARGET="$fuzz_target" \
            "$WORKER_IMAGE"

        # Store container ID
        container_id=$(docker ps -q --filter "name=$container_name")
        worker_containers+=("$container_id")

        echo "[$(date)] Started worker container: $container_name (ID: $container_id)"
    done <<< "$fuzz_targets"
done

echo "All workers started. Waiting for completion..."

# Function to check if all containers are done
all_workers_done() {
    for container_id in "${worker_containers[@]}"; do
        # Check if container is still running
        if docker ps -q --filter "id=$container_id" | grep -q .; then
            return 1 # At least one container is still running
        fi
    done
    return 0 # All done
}

# Wait for all workers to complete with status updates
completed_count=0
total_count=${#worker_containers[@]}

while ! all_workers_done; do
    new_completed=$(( total_count - $(docker ps -q --filter "ancestor=$WORKER_IMAGE" | wc -l) ))

    if [ "$new_completed" -gt "$completed_count" ]; then
        completed_count=$new_completed
        percent=$(( completed_count * 100 / total_count ))
        echo "[$(date)] Progress: $completed_count/$total_count packages completed ($percent%)"
    fi

    sleep 5
done

echo "All workers have completed"

# Clean up all worker containers
# echo "Cleaning up worker containers..."
# for container_id in "${worker_containers[@]}"; do
#     docker rm -f "$container_id" >/dev/null 2>&1 || true
# done

echo "Container cleanup complete"

# Create metadata file with timestamp
cat > "$CORPUS_DIR/.fuzzer-metadata.json" <<EOF
{
    "last_run": "$(date -Iseconds)",
    "target_repo": "$TARGET_REPO",
    "corpus_repo": "$CORPUS_REPO",
    "fuzz_time": "$FUZZ_TIME",
    "packages_processed": $total_packages,
    "parallel_workers": $total_packages
}
EOF

echo "Fuzzing cycle completed successfully at $(date)"