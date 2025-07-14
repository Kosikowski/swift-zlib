# Windows Testing Guide for SwiftZlib

This guide explains how to run the SwiftZlib tests on Windows using GitHub Actions.

## 🚀 Quick Start

The Windows tests run automatically on:

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

## 📋 What Gets Tested

### **Main Test Job**

- **Platform**: Windows Server 2022
- **Swift Version**: 5.9.2
- **Tests**: All test suites including Core, Extensions, File Operations, Error Handling, Streaming, and Concurrency

### **Build Verification**

- **Debug and Release builds** on Windows
- **CLI tool compilation** verification
- **Package building** in both configurations

### **Performance Benchmarks**

- **Compression performance** tests
- **Decompression performance** tests
- **Memory efficiency** tests

## 🔧 Local Windows Testing

If you want to test locally on Windows:

### **Prerequisites**

1. **Swift for Windows 5.9.2**

   - Download from: https://www.swift.org/download/
   - Install the Windows version

2. **Visual Studio Build Tools 2019**

   - Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019
   - Install with C++ workload

3. **zlib Development Libraries**

   ```powershell
   # Install vcpkg
   git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
   C:\vcpkg\bootstrap-vcpkg.bat

   # Install zlib
   C:\vcpkg\vcpkg install zlib:x64-windows
   ```

### **Running Tests Locally**

```powershell
# Navigate to project directory
cd C:\path\to\swift-zlib

# Build the project
swift build

# Run all tests
swift test --verbose

# Run specific test groups
swift test --filter CoreTests
swift test --filter ExtensionsTests
swift test --filter FileOperationsTests

# Build CLI tool
swift build --product SwiftZlibCLI
```

## 📊 Test Coverage

The Windows CI tests include:

- **Core Tests**: Basic compression/decompression functionality
- **Streaming Tests**: Stream-based operations
- **File Operations**: File compression/decompression
- **Error Handling**: Error scenarios and edge cases
- **Performance Tests**: Performance benchmarks
- **Advanced Features**: Dictionary compression, gzip headers, etc.
- **CLI Tool**: Command-line interface compilation and testing

## 🔍 Troubleshooting

### **Common Issues**

1. **Swift not found**

   - Ensure Swift for Windows is properly installed
   - Check PATH environment variable includes `C:\swift\bin`

2. **zlib not found**

   - Install zlib via vcpkg: `C:\vcpkg\vcpkg install zlib:x64-windows`
   - Ensure vcpkg is properly bootstrapped

3. **Build tools missing**

   - Install Visual Studio 2019 Build Tools
   - Ensure C++ workload is installed

4. **GitHub Actions failures**
   - Check the Actions tab in your repository
   - Review the logs for specific error messages
   - Ensure the workflow file is in `.github/workflows/`

### **Debugging Local Issues**

```powershell
# Check Swift installation
swift --version

# Check zlib installation
C:\vcpkg\vcpkg list | findstr zlib

# Manual build test
swift build -v

# Run tests with more verbose output
swift test -v --filter CoreTests
```

## 📈 Performance Considerations

- Windows builds may be slower than macOS/Linux
- Performance tests are run separately to avoid timeouts
- Build verification runs both debug and release configurations

## 🔄 Integration with Existing CI

The Windows workflow integrates with the existing CI pipeline:

- **macOS Tests**: Xcode 15.2, Swift 5.10.1
- **Linux Tests**: Ubuntu 24.04, Swift 5.10.1
- **Windows Tests**: Windows Server 2022, Swift 5.9.2

All platforms run the same test suites for consistency.

## 📝 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs for specific errors
3. Verify all prerequisites are installed locally
4. Run with verbose output for more details: `swift test -v`
