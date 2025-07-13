# Continuous Integration & Deployment

SwiftZlib uses GitHub Actions for comprehensive continuous integration testing across multiple platforms and configurations.

## CI Workflow Overview

The CI pipeline runs on every push to `main`/`develop` branches and on all pull requests.

### Test Matrix

| Platform     | Runner         | Xcode/Swift | Purpose              |
| ------------ | -------------- | ----------- | -------------------- |
| macOS 12     | `macos-12`     | Xcode 14.3  | Legacy compatibility |
| macOS 14     | `macos-14`     | Xcode 15.2  | Latest features      |
| Ubuntu 22.04 | `ubuntu-22.04` | Swift 5.9   | Linux compatibility  |
| Ubuntu 22.04 | `ubuntu-22.04` | Swift 5.10  | Latest Swift         |

## Jobs Breakdown

### 1. Platform Testing

#### macOS (Legacy)

- **Runner**: `macos-12`
- **Xcode**: 14.3
- **Purpose**: Ensure compatibility with older macOS/Xcode versions
- **Tests**: All test suites + specific test groups

#### macOS (Latest)

- **Runner**: `macos-14`
- **Xcode**: 15.2
- **Purpose**: Test with latest macOS/Xcode features
- **Tests**: All test suites + specific test groups

#### Linux (Stable)

- **Runner**: `ubuntu-22.04`
- **Swift**: 5.9
- **Purpose**: Linux compatibility testing
- **Dependencies**: `zlib1g-dev`
- **Tests**: All test suites + specific test groups

#### Linux (Latest)

- **Runner**: `ubuntu-22.04`
- **Swift**: 5.10
- **Purpose**: Latest Swift features on Linux
- **Dependencies**: `zlib1g-dev`
- **Tests**: All test suites + specific test groups

### 2. CLI Tool Testing

- **Platform**: macOS 14
- **Purpose**: Verify CLI tool functionality
- **Tests**:
  - Build CLI tool in release mode
  - Test help command
  - Test info command
  - Test compression/decompression round-trip
  - Verify file integrity

### 3. Performance Benchmarks

- **Platform**: macOS 14
- **Purpose**: Monitor performance regressions
- **Tests**:
  - Compression performance
  - Decompression performance
  - Memory efficiency tests
  - Large file handling

### 4. Code Quality

- **Platform**: macOS 14
- **Purpose**: Maintain code quality standards
- **Checks**:
  - Swift formatting (SwiftFormat)
  - TODO/FIXME comment detection
  - Documentation coverage
  - Public API documentation

### 5. Security Checks

- **Platform**: macOS 14
- **Purpose**: Security and dependency validation
- **Checks**:
  - Dependency analysis
  - Package resolution
  - Security scanning (placeholder for tools like CodeQL)

### 6. Build Verification

- **Matrix**: Debug/Release × macOS/Linux
- **Purpose**: Ensure builds work in all configurations
- **Tests**:
  - Package build verification
  - CLI tool build verification
  - Test execution in all configurations

## Test Groups

The CI runs specific test groups to ensure comprehensive coverage:

```bash
swift test --filter CoreTests
swift test --filter ExtensionsTests
swift test --filter FileOperationsTests
swift test --filter CombineTests
swift test --filter PerformanceTests
swift test --filter ErrorHandlingTests
swift test --filter StreamingTests
swift test --filter ConcurrencyTests
```

## Local CI Testing

### Prerequisites

```bash
# Install SwiftFormat (optional)
brew install swiftformat

# Install zlib development headers (Linux)
sudo apt-get install zlib1g-dev
```

### Run CI Locally

```bash
# Run all tests
swift test --verbose

# Run specific test groups
swift test --filter CoreTests
swift test --filter PerformanceTests

# Build CLI tool
swift build -c release --product SwiftZlibCLI

# Test CLI functionality
.build/release/SwiftZlibCLI --help
.build/release/SwiftZlibCLI info
```

### Code Quality Checks

```bash
# Check formatting
swiftformat --lint Sources/ Tests/

# Check for TODO/FIXME comments
grep -r "TODO\|FIXME" Sources/ Tests/

# Check documentation coverage
find Sources/ -name "*.swift" -exec grep -l "public" {} \; | while read file; do
  if ! grep -q "///" "$file"; then
    echo "Warning: $file has public APIs but no documentation comments"
  fi
done
```

## CI Best Practices

### 1. Fast Feedback

- Tests run in parallel across platforms
- Fail-fast on critical errors
- Separate jobs for different concerns

### 2. Comprehensive Coverage

- Multiple Swift/Xcode versions
- Cross-platform testing
- Performance monitoring
- Code quality checks

### 3. Reliability

- Explicit dependency installation
- Version pinning for tools
- Clear error reporting
- Retry mechanisms for flaky tests

### 4. Security

- Dependency scanning
- Security tool integration
- Regular dependency updates

## Troubleshooting CI

### Common Issues

#### Build Failures

```bash
# Clean and rebuild
swift package clean
swift build
swift test
```

#### Test Discovery Issues

```bash
# List all tests
swift test --list-tests

# Check test discovery
grep -r "static var allTests" Tests/
```

#### Performance Test Failures

```bash
# Run performance tests separately
swift test --filter PerformanceTests --verbose

# Check system resources
top -l 1 | head -10
```

#### Linux-Specific Issues

```bash
# Ensure zlib headers are installed
sudo apt-get update && sudo apt-get install -y zlib1g-dev

# Check Swift installation
swift --version
which swift
```

### Debugging CI

#### Enable Debug Output

```yaml
- name: Run tests with debug
  run: swift test --verbose --debug-info
```

#### Check Environment

```yaml
- name: Debug environment
  run: |
    swift --version
    xcodebuild -version
    uname -a
    df -h
```

#### Test Specific Components

```yaml
- name: Test specific component
  run: swift test --filter "testSpecificFunction"
```

## Future Enhancements

### Planned Improvements

1. **Code Coverage**

   - Add code coverage reporting
   - Set minimum coverage thresholds
   - Coverage trend analysis

2. **Performance Monitoring**

   - Performance regression detection
   - Benchmark result storage
   - Performance trend analysis

3. **Security Scanning**

   - GitHub CodeQL integration
   - Dependency vulnerability scanning
   - SAST/DAST integration

4. **Deployment Automation**

   - Automatic releases on tags
   - Documentation deployment
   - Package distribution

5. **Advanced Testing**
   - Fuzzing tests
   - Memory leak detection
   - Stress testing

### Integration Opportunities

- **SonarQube**: Code quality analysis
- **Snyk**: Dependency vulnerability scanning
- **Codecov**: Code coverage reporting
- **GitHub Pages**: Documentation hosting
- **GitHub Releases**: Automated releases

## Configuration Files

- `.github/workflows/tests.yml`: Main CI workflow
- `.github/ISSUE_TEMPLATE/`: Issue templates
- `.swiftformat`: Code formatting rules
- `Package.swift`: Package configuration

## Monitoring

### CI Metrics

- Build success rate
- Test execution time
- Performance benchmark trends
- Code coverage trends
- Security scan results

### Alerts

- Build failures
- Performance regressions
- Security vulnerabilities
- Code quality degradation

This CI/CD setup ensures SwiftZlib maintains high quality, cross-platform compatibility, and reliable performance across all supported environments.
