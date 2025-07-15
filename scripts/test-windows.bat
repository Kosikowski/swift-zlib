@echo off
setlocal enabledelayedexpansion

echo Starting SwiftZlib Windows tests...

REM Check if Swift is available
swift --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Swift not found. Please install Swift for Windows.
    exit /b 1
)

echo Swift found:
swift --version

REM Check if zlib is available via vcpkg
vcpkg list | findstr zlib >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: zlib not found via vcpkg. Attempting to install...
    vcpkg install zlib:x64-windows
    if %errorlevel% neq 0 (
        echo Error: Failed to install zlib. Please install zlib development libraries.
        exit /b 1
    )
)

echo zlib found.

REM Build the project
echo Building SwiftZlib...
if "%1"=="-v" (
    swift build -v
) else (
    swift build
)

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

REM Run tests
echo Running tests...
if "%1"=="-v" (
    swift test -v
) else (
    swift test
)

if %errorlevel% equ 0 (
    echo All tests passed!
) else (
    echo Some tests failed!
    exit /b 1
)
