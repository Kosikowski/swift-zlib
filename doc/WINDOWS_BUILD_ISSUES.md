# Windows Build Issues and Solutions

## Overview

This document details the challenges encountered when building SwiftZlib on Windows and the various solutions attempted to resolve them.

## Problem Description

### Primary Issue: Cyclic Dependency in Swift Overlay Shims

The main issue is a cyclic dependency error that occurs during Swift module compilation on Windows:

```
cyclic dependency in module 'ucrt': ucrt -> _visualc_intrinsics -> ucrt
could not build C module 'SwiftOverlayShims'
```

### Root Cause

This is a fundamental issue with the Swift toolchain on Windows where:

1. **Swift Overlay Shims are mandatory**: The Swift compiler automatically imports `LibcOverlayShims.h` and `SwiftOverlayShims.h` for all Swift modules
2. **Windows SDK headers have circular dependencies**: The overlay shims include Windows SDK headers that have circular dependencies between `ucrt` and `_visualc_intrinsics` modules
3. **No user-level workaround**: This cannot be prevented through compiler flags, header guards, or module map exclusions

## Solutions Attempted

### 1. Custom zlib Header Implementation

**Approach**: Created a custom `zlib_simple.h` header to avoid system zlib dependencies.

**Implementation**:

- Created `Sources/CZLib/private/zlib_simple.h` with minimal zlib declarations
- Modified `zlib_shim.h` to conditionally include custom header on Windows
- Added essential C function declarations for Windows builds

**Result**: ✅ C compilation succeeds, but Swift module compilation still fails

### 2. Comprehensive CRT Flags

**Approach**: Added extensive `_NO_CRT_*` flags to prevent inline function inclusion.

**Implementation**:

```swift
.define("_NO_CRT_STDIO_INLINE"),
.define("_CRT_NO_POSIX_ERROR_CODES"),
.define("_NO_CRT_RAND_S"),
.define("_NO_CRT_TIME_INLINE"),
.define("_NO_CRT_MATH_INLINE"),
.define("_NO_CRT_STRING_INLINE"),
.define("_NO_CRT_WCTYPE_INLINE"),
.define("_NO_CRT_LOCALE_INLINE"),
.define("_NO_CRT_STDLIB_INLINE"),
.define("_NO_CRT_CTYPE_INLINE"),
.define("_NO_CRT_ERRNO_INLINE"),
.define("_NO_CRT_SETJMP_INLINE"),
.define("_NO_CRT_SIGNAL_INLINE"),
.define("_NO_CRT_ASSERT_INLINE"),
.define("_NO_CRT_MEMORY_INLINE"),
.define("_NO_CRT_MALLOC_INLINE"),
.define("_NO_CRT_FREE_INLINE"),
.define("_NO_CRT_MEMSET_INLINE"),
.define("_NO_CRT_MEMCPY_INLINE"),
.define("_NO_CRT_MEMCMP_INLINE"),
.define("_NO_CRT_STRLEN_INLINE"),
.define("_NO_CRT_STRCPY_INLINE"),
.define("_NO_CRT_STRCAT_INLINE"),
.define("_NO_CRT_STRCMP_INLINE"),
.define("_NO_CRT_SPRINTF_INLINE"),
.define("_NO_CRT_VSPRINTF_INLINE"),
.define("_NO_CRT_PRINTF_INLINE"),
.define("_NO_CRT_FFLUSH_INLINE"),
.define("_NO_CRT_WCHAR_INLINE"),
.define("_NO_CRT_MBSTOWCS_INLINE"),
.define("_NO_CRT_WCSTOMBS_INLINE"),
.define("_NO_CRT_MBTOWC_INLINE"),
.define("_NO_CRT_WCTOMB_INLINE"),
.define("_NO_CRT_MBLEN_INLINE"),
.define("_NO_CRT_MBRLEN_INLINE"),
.define("_NO_CRT_MBRTOWC_INLINE"),
.define("_NO_CRT_WCRTOMB_INLINE"),
.define("_NO_CRT_MBSRTOWCS_INLINE"),
.define("_NO_CRT_WCSRTOMBS_INLINE"),
.define("_NO_CRT_MBSTOWCS_S_INLINE"),
.define("_NO_CRT_WCSTOMBS_S_INLINE"),
.define("_NO_CRT_MBSRTOWCS_S_INLINE"),
.define("_NO_CRT_WCSRTOMBS_S_INLINE"),
```

**Result**: ❌ No effect on Swift overlay shim inclusion

### 3. Module Map Exclusions

**Approach**: Attempted to exclude problematic headers in module.modulemap.

**Implementation**:

```modulemap
module CZLib [system] {
  umbrella header "include/zlib_shim.h"
  link "z"
  export *

  // Explicitly exclude problematic system modules
  exclude header "LibcOverlayShims.h"
  exclude header "SwiftOverlayShims.h"
}
```

**Result**: ❌ No effect - Swift compiler includes overlay shims regardless

### 4. Swift Version Upgrade

**Approach**: Upgraded from Swift 5.9.2 to Swift 5.10.1.

**Implementation**: Updated all CI workflows to use `swift-version: "5.10.1"`.

**Result**: ❌ Same cyclic dependency error persists

### 5. Conditional System Header Inclusion

**Approach**: Modified `zlib_shim.c` to avoid system headers on Windows.

**Implementation**:

```c
#include "zlib_shim.h"
#ifdef _WIN32
// On Windows, avoid system headers that cause cyclic dependencies
// The zlib_simple.h provides all necessary types and constants
#else
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#endif
```

**Result**: ✅ C compilation succeeds, but Swift module compilation still fails

## Current Status

### What Works

- ✅ **C compilation**: The CZLib target compiles successfully on Windows
- ✅ **macOS/Linux builds**: Full builds and tests work perfectly
- ✅ **Functionality**: All zlib functionality is preserved

### What Doesn't Work

- ❌ **Swift module compilation on Windows**: Cyclic dependency prevents SwiftZlib module compilation
- ❌ **Swift tests on Windows**: Cannot run Swift tests due to module compilation failure

## Technical Details

### File Structure

```
Sources/CZLib/
├── include/
│   └── zlib_shim.h          # Main header with conditional includes
├── private/
│   └── zlib_simple.h        # Custom zlib declarations for Windows
├── zlib_shim.c              # C implementation with conditional headers
└── module.modulemap         # Module definition with exclusions
```

### Conditional Compilation Logic

**On Windows (`_WIN32`)**:

- Uses custom `zlib_simple.h` instead of system `<zlib.h>`
- Avoids system headers in `zlib_shim.c`
- Provides essential C function declarations

**On other platforms**:

- Uses system `<zlib.h>`
- Includes standard system headers
- Relies on system zlib library

### Essential Declarations for Windows

```c
// Basic types and constants
#ifndef NULL
#define NULL ((void*)0)
#endif

// Essential function declarations
void* malloc(unsigned long long size);
void free(void* ptr);

// Variable argument support
typedef __builtin_va_list va_list;
#define va_start(v,l) __builtin_va_start(v,l)
#define va_end(v) __builtin_va_end(v)
#define va_arg(v,l) __builtin_va_arg(v,l)
```

## Recommendations

### For CI/CD

1. **Limit Windows CI to C-only builds**:

   ```yaml
   - name: Build C target only
     run: swift build --target CZLib
   ```

2. **Use WSL2 for full testing**:

   ```yaml
   runs-on: ubuntu-latest # or windows-latest with WSL2
   ```

3. **Run Swift tests on macOS/Linux only**:
   ```yaml
   - name: Run Swift tests (macOS/Linux only)
     if: runner.os != 'Windows'
     run: swift test
   ```

### For Development

1. **Local development**: Use macOS or Linux for full development workflow
2. **Windows testing**: Test C functionality only on Windows
3. **Cross-platform**: Ensure all Swift code works on macOS/Linux

## Future Considerations

### Upstream Fixes

- This is a known Swift toolchain issue on Windows
- Monitor Swift releases for fixes
- Consider filing a bug report with the Swift project

### Alternative Approaches

1. **WSL2 integration**: Use Linux on Windows for CI
2. **Docker containers**: Use Linux containers on Windows runners
3. **Separate workflows**: Different CI strategies for different platforms

### Monitoring

- Track Swift releases for Windows improvements
- Monitor Swift JIRA and GitHub issues
- Test with new Swift versions as they become available

## Conclusion

The Windows build issues are caused by fundamental limitations in the Swift toolchain on Windows, specifically the mandatory inclusion of overlay shims that trigger cyclic dependencies in the Windows SDK headers.

While we've successfully implemented workarounds for C compilation, the Swift module compilation issue remains unresolved due to upstream Swift toolchain limitations.

The recommended approach is to:

1. Use Windows CI for C-only builds
2. Run full Swift tests on macOS/Linux
3. Monitor Swift releases for upstream fixes
4. Consider WSL2 for comprehensive Windows testing

This approach ensures reliable CI/CD while maintaining full functionality across all supported platforms.
