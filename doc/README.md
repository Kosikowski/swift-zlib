# SwiftZlib Documentation

This directory contains comprehensive documentation for SwiftZlib, a Swift wrapper for the zlib compression library.

## Documentation Index

### User Guides

- **[STREAMING.md](STREAMING.md)** - Streaming compression and decompression with configuration, usage patterns, and best practices
- **[ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)** - Async/await, Combine integration, dictionary compression, and performance optimization
- **[GZIP_SUPPORT.md](GZIP_SUPPORT.md)** - Gzip header handling, metadata management, and file operations
- **[ERROR_HANDLING.md](ERROR_HANDLING.md)** - Error types, recovery strategies, debugging techniques, and best practices

### Technical Documentation

- **[API_COVERAGE.md](API_COVERAGE.md)** - Complete mapping from C zlib functions to Swift methods (~98% coverage)
- **[API_REFERENCE.md](API_REFERENCE.md)** - Comprehensive API reference with all public types, methods, and examples
- **[TESTING.md](TESTING.md)** - Test structure, running tests, writing tests, debugging, and best practices
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - System architecture, design patterns, and component relationships

### Specialized Topics

- **[DICTIONARY_COMPRESSION.md](DICTIONARY_COMPRESSION.md)** - Dictionary compression requirements and usage patterns
- **[PRIMING.md](PRIMING.md)** - Advanced priming functionality and limitations

## Quick Navigation

### Getting Started
1. **[Main README](../README.md)** - Installation, quick start, and basic usage
2. **[STREAMING.md](STREAMING.md)** - For large file processing
3. **[ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)** - For modern Swift features

### Technical Reference
1. **[API_COVERAGE.md](API_COVERAGE.md)** - C to Swift function mapping
2. **[API_REFERENCE.md](API_REFERENCE.md)** - Complete API documentation
3. **[ARCHITECTURE.md](../ARCHITECTURE.md)** - System design and architecture

### Troubleshooting
1. **[ERROR_HANDLING.md](ERROR_HANDLING.md)** - Error handling and recovery
2. **[TESTING.md](TESTING.md)** - Testing and debugging
3. **[Main README Troubleshooting](../README.md#troubleshooting)** - Common issues

## Documentation Philosophy

- **User-Focused**: Guides prioritize practical usage over technical details
- **Progressive Disclosure**: Start simple, add complexity as needed
- **Complete Coverage**: All features documented with examples
- **Error Handling**: Comprehensive error scenarios and recovery
- **Performance**: Optimization tips and best practices throughout

## Contributing to Documentation

When adding new features or making changes:

1. Update the relevant documentation file
2. Add examples and usage patterns
3. Include error handling scenarios
4. Update this index if adding new files
5. Ensure cross-references are accurate

## External Resources

- **[zlib Manual](https://zlib.net/manual.html)** - Official zlib documentation
- **[Swift Package Manager](https://swift.org/package-manager/)** - Package management
- **[Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)** - Async/await guide 