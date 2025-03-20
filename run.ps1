# run.ps1 - Start angry-fuzzer with configurable options

# Default values
$TARGET_REPO = ""
$CORPUS_REPO = ""
$FUZZ_TIME = "5m"
$TEMP_DIR = "/tmp/angry-fuzzer"
$HELP = $false

# Parse command line arguments
$i = 0
while ($i -lt $args.Count) {
    $arg = $args[$i]

    switch ($arg) {
        "--target" {
            $TARGET_REPO = $args[$i+1]
            $i += 2
        }
        "--corpus" {
            $CORPUS_REPO = $args[$i+1]
            $i += 2
        }
        "--time" {
            $FUZZ_TIME = $args[$i+1]
            $i += 2
        }
        "--temp" {
            $TEMP_DIR = $args[$i+1]
            $i += 2
        }
        "--help" {
            $HELP = $true
            $i += 1
        }
        default {
            Write-Host "Unknown option: $arg"
            Write-Host "Use --help to see available options"
            exit 1
        }
    }
}

# Display help message
if ($HELP) {
    Write-Host "Usage: .\run.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --target URL     Target repository URL (required)"
    Write-Host "  --corpus URL     Corpus repository URL"
    Write-Host "  --time DURATION  Fuzzing duration per test (default: 5m)"
    Write-Host "  --temp DIR       Temporary directory (default: C:/tmp/angry-fuzzer)"
    Write-Host "  --help           Show this help message"
    exit 0
}

# Validate required parameters
if ([string]::IsNullOrEmpty($TARGET_REPO)) {
    Write-Host "Error: Target repository URL is required"
    Write-Host "Use --help to see available options"
    exit 1
}

# Export variables for docker-compose
$env:TARGET_REPO = $TARGET_REPO
$env:CORPUS_REPO = $CORPUS_REPO
$env:FUZZ_TIME = $FUZZ_TIME
$env:TEMP_DIR = $TEMP_DIR

# Create temporary directory
if (-not (Test-Path -Path $TEMP_DIR)) {
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
}

# Display configuration
Write-Host "Starting angry-fuzzer with the following configuration:"
Write-Host "Target repository: $TARGET_REPO"
if ([string]::IsNullOrEmpty($CORPUS_REPO)) {
    Write-Host "Corpus repository: None (using empty corpus)"
} else {
    Write-Host "Corpus repository: $CORPUS_REPO"
}
Write-Host "Fuzz duration: $FUZZ_TIME"
Write-Host "Temporary directory: $TEMP_DIR"
Write-Host ""

# Start the controller
docker compose build
docker compose up controller