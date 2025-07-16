#!/usr/bin/env python3
"""
Check that all XCTestCase subclasses have proper allTests properties.

This script ensures that all test classes have a static allTests property
for Linux test discovery compatibility with Swift Package Manager.

Usage:
    python scripts/check_alltests.py
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Optional


class TestClassInfo:
    def __init__(self, filename: str, class_name: str, line_number: int):
        self.filename = filename
        self.class_name = class_name
        self.line_number = line_number
        self.has_alltests = False
        self.alltests_signature = None
        self.test_methods = []
        self.alltests_methods = []


def find_test_files() -> List[Path]:
    """Find all Swift test files."""
    test_dir = Path("Tests/SwiftZlibTests")
    if not test_dir.exists():
        print("❌ Tests/SwiftZlibTests directory not found")
        return []

    swift_files = []
    for file_path in test_dir.rglob("*.swift"):
        swift_files.append(file_path)

    return swift_files


def extract_test_classes(file_path: Path) -> List[TestClassInfo]:
    """Extract test class information from a Swift file."""
    classes = []

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

    # Find XCTestCase subclasses
    class_pattern = r'^\s*(?:final\s+)?class\s+(\w+)\s*:\s*XCTestCase'

    for i, line in enumerate(lines, 1):
        match = re.match(class_pattern, line.strip())
        if match:
            class_name = match.group(1)
            classes.append(TestClassInfo(str(file_path), class_name, i))

    return classes


def analyze_test_class(file_path: Path, test_class: TestClassInfo) -> None:
    """Analyze a test class for allTests property and test methods."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

    # Find allTests property
    alltests_patterns = [
        r'^\s*static\s+(?:var|let)\s+allTests\s*[:=]',
        r'^\s*static\s+let\s+allTests\s*:\s*\[\(String,\s*\([^)]+\)\s*->\s*\(\)\s*throws\s*->\s*Void\)\]\s*=',
    ]

    for i, line in enumerate(lines, 1):
        for pattern in alltests_patterns:
            if re.search(pattern, line):
                test_class.has_alltests = True
                test_class.alltests_signature = line.strip()
                break

    # Find test methods
    test_method_pattern = r'^\s*func\s+(test\w+)\s*\([^)]*\)\s*(?:throws\s+)?(?:async\s+)?(?:throws\s+)?(?:async\s+)?\s*\{'

    for i, line in enumerate(lines, 1):
        match = re.search(test_method_pattern, line)
        if match:
            method_name = match.group(1)
            test_class.test_methods.append(method_name)

    # Find methods in allTests array
    if test_class.has_alltests:
        # Look for the allTests array content
        in_alltests = False
        for line in lines:
            if 'static' in line and 'allTests' in line and '=' in line:
                in_alltests = True
                continue

            if in_alltests:
                # Look for method references in the array
                method_match = re.search(r'"([^"]+)"', line)
                if method_match:
                    method_name = method_match.group(1)
                    test_class.alltests_methods.append(method_name)

                # Check if we've reached the end of the array
                if line.strip().endswith(']'):
                    break


def check_alltests_coverage(test_class: TestClassInfo) -> List[str]:
    """Check if allTests includes all test methods."""
    issues = []

    if not test_class.has_alltests:
        issues.append(f"❌ Missing allTests property")
        return issues

    # Check signature
    if 'static var allTests' not in test_class.alltests_signature:
        issues.append(f"⚠️  Consider using 'static var allTests' for consistency")

    # Check method coverage
    missing_methods = set(test_class.test_methods) - set(test_class.alltests_methods)
    extra_methods = set(test_class.alltests_methods) - set(test_class.test_methods)

    if missing_methods:
        issues.append(f"❌ Missing test methods in allTests: {', '.join(missing_methods)}")

    if extra_methods:
        issues.append(f"⚠️  Extra methods in allTests (may be intentional): {', '.join(extra_methods)}")

    return issues


def main() -> int:
    """Main function to check allTests properties."""
    print("🔍 Checking allTests properties in test files...")

    test_files = find_test_files()
    if not test_files:
        print("❌ No test files found")
        return 1

    all_issues = []
    test_classes = []

    for file_path in test_files:
        classes = extract_test_classes(file_path)
        for test_class in classes:
            analyze_test_class(file_path, test_class)
            test_classes.append(test_class)

    print(f"\n📊 Found {len(test_classes)} test classes in {len(test_files)} files")

    for test_class in test_classes:
        issues = check_alltests_coverage(test_class)
        if issues:
            print(f"\n📁 {test_class.filename}:{test_class.line_number} - {test_class.class_name}")
            for issue in issues:
                print(f"   {issue}")
            all_issues.extend(issues)

    if not all_issues:
        print("\n✅ All test classes have proper allTests properties!")
        return 0
    else:
        print(f"\n❌ Found {len(all_issues)} issues with allTests properties")
        print("\n💡 Recommendations:")
        print("   - Add 'static var allTests = [...]' to missing classes")
        print("   - Include all test methods in allTests array")
        print("   - Use consistent signature: static var allTests = [...]")
        return 1


if __name__ == "__main__":
    sys.exit(main())
