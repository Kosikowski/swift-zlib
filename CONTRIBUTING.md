# Contributing to SwiftZlib

## Development Setup

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality and consistency. The hooks include:

- **SwiftFormat**: Automatic Swift code formatting
- **General file checks**: Trailing whitespace, file endings, merge conflicts
- **YAML/Markdown formatting**: Consistent formatting for documentation
- **Security checks**: Detect potential secrets in code

#### Quick Setup

```bash
# Run the setup script (recommended)
./scripts/setup-pre-commit.sh

# Or install manually
pip3 install pre-commit
brew install swiftformat
pre-commit install
```

#### Manual Installation

1. Install pre-commit:
   ```bash
   pip3 install pre-commit
   # or
   brew install pre-commit
   ```

2. Install SwiftFormat:
   ```bash
   brew install swiftformat
   ```

3. Install the hooks:
   ```bash
   pre-commit install
   ```

#### Available Commands

- `pre-commit run --all-files` - Run all hooks on all files
- `pre-commit run swiftformat` - Run only SwiftFormat
- `pre-commit run` - Run hooks on staged files
- `pre-commit clean` - Clean pre-commit cache
- `pre-commit uninstall` - Remove pre-commit hooks

## Coding Style

- Follow Swift best practices
- Use consistent naming conventions
- All code must pass SwiftFormat formatting
- Document public APIs with comprehensive comments

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `swift test`
5. Ensure code formatting: `swiftformat .`
6. Commit your changes (pre-commit hooks will run automatically)
7. Push to your fork
8. Submit a pull request

## Test Requirements

- All tests must pass before submitting a PR
- New features require corresponding tests
- Maintain or improve test coverage
- Run performance tests for performance-critical changes

### Running Tests

```bash
# Run all tests
swift test

# Run specific test groups
swift test --filter CoreTests
swift test --filter PerformanceTests

# Run with verbose output
swift test --verbose
```

## Documentation Guidelines

- Document all public APIs
- Keep README and documentation up to date
- Add examples for new features
- Update architecture documentation for significant changes

## Code Quality

- No TODO/FIXME comments in production code
- Follow the established architecture patterns
- Use appropriate error handling
- Consider performance implications
- Write clear, readable code 