---
name: Bug report
about: Create a report to help us improve SwiftZlib
title: "[BUG] "
labels: ["bug"]
assignees: ""
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Use method '...'
2. Pass data '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
A clear and concise description of what actually happened.

**Environment:**

- OS: [e.g. macOS 14.0, Ubuntu 22.04]
- Swift version: [e.g. 5.9, 5.10]
- Xcode version: [e.g. 15.2] (if applicable)
- SwiftZlib version: [e.g. 1.0.0]

**Code example**

```swift
// Minimal code example that reproduces the issue
let data = "test".data(using: .utf8)!
let compressed = try data.compress()
```

**Additional context**
Add any other context about the problem here, such as:

- Error messages
- Stack traces
- Performance impact
- Workarounds you've tried
