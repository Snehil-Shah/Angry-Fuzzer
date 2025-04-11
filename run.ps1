# run.ps1 - Start angry-fuzzer with configurable options

# Load GitHub token from .env file if it exists
if (Test-Path ".env") {
    Write-Host "Loading GitHub token from .env file"
    # Only load GITHUB_TOKEN from .env file
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^GITHUB_TOKEN=(.*)' -and -not $_.StartsWith('#')) {
            $env:GITHUB_TOKEN = $matches[1]
        }
    }
}

# Default values
$TARGET_REPO = ""
$CORPUS_REPO = ""
$FUZZ_TIME = "30s"
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
        "--no-push" {
            $PUSH_CORPUS = $false
            $i += 1
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
    Write-Host "  --time DURATION  Fuzzing duration per test (default: 30s)"
    Write-Host "  --temp DIR       Temporary directory (default: /tmp/angry-fuzzer)"
    Write-Host "  --help           Show this help message"
    Write-Host ""
    Write-Host "GitHub authentication:"
    Write-Host "  Create a .env file with your GitHub token for repository access:"
    Write-Host "  GITHUB_TOKEN=your_github_token_here"
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
if (-not [string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    Write-Host "GitHub token: [Set]"
} else {
    Write-Host "GitHub token: [Not set]"
}
Write-Host ""

# Start the controller
docker compose build
docker compose up controller