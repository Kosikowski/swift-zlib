# Windows test script for SwiftZlib
param(
    [switch]$BuildOnly,
    [switch]$Verbose,
    [string]$TestFilter = ""
)

Write-Host "Starting SwiftZlib Windows tests..." -ForegroundColor Green

# Check if Swift is available
try {
    $swiftVersion = swift --version
    Write-Host "Swift version found:" -ForegroundColor Green
    Write-Host $swiftVersion
} catch {
    Write-Host "Swift not found. Please install Swift for Windows." -ForegroundColor Red
    exit 1
}

# Check if zlib is available
try {
    $zlibTest = pkg-config --exists zlib
    if ($LASTEXITCODE -eq 0) {
        Write-Host "zlib found via pkg-config" -ForegroundColor Green
    } else {
        Write-Host "zlib not found via pkg-config, checking vcpkg..." -ForegroundColor Yellow
        # Check if vcpkg zlib is available
        $vcpkgZlib = vcpkg list | Select-String "zlib"
        if ($vcpkgZlib) {
            Write-Host "zlib found via vcpkg" -ForegroundColor Green
        } else {
            Write-Host "zlib not found. Please install zlib development libraries." -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "pkg-config not available, checking vcpkg..." -ForegroundColor Yellow
}

# Build the project
Write-Host "Building SwiftZlib..." -ForegroundColor Green
if ($Verbose) {
    swift build -v
} else {
    swift build
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

if ($BuildOnly) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    exit 0
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Green
if ($TestFilter) {
    if ($Verbose) {
        swift test --filter $TestFilter -v
    } else {
        swift test --filter $TestFilter
    }
} else {
    if ($Verbose) {
        swift test -v
    } else {
        swift test
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
    exit 1
}
