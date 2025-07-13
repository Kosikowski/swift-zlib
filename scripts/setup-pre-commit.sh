#!/bin/bash

# Setup script for pre-commit hooks with SwiftFormat
# This script installs pre-commit and configures it for the SwiftZlib project

set -e

echo "🚀 Setting up pre-commit hooks for SwiftZlib..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    
    # Try different installation methods
    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    elif command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v brew &> /dev/null; then
        brew install pre-commit
    else
        echo "❌ Error: Could not install pre-commit. Please install it manually:"
        echo "   pip3 install pre-commit"
        echo "   or"
        echo "   brew install pre-commit"
        exit 1
    fi
else
    echo "✅ pre-commit is already installed"
fi

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "📦 Installing SwiftFormat..."
    
    if command -v brew &> /dev/null; then
        brew install swiftformat
    else
        echo "❌ Error: Could not install SwiftFormat. Please install it manually:"
        echo "   brew install swiftformat"
        exit 1
    fi
else
    echo "✅ SwiftFormat is already installed"
fi

# Install pre-commit hooks
echo "🔧 Installing pre-commit hooks..."
pre-commit install

# Install pre-commit hooks for all supported hooks
echo "🔧 Installing pre-commit hooks for all supported hooks..."
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push
pre-commit install --hook-type commit-msg

# Run pre-commit on all files to ensure everything is formatted
echo "🎨 Running pre-commit on all files..."
pre-commit run --all-files

echo "✅ Pre-commit setup complete!"
echo ""
echo "📋 Available commands:"
echo "   pre-commit run --all-files    # Run all hooks on all files"
echo "   pre-commit run swiftformat    # Run only SwiftFormat"
echo "   pre-commit run                # Run hooks on staged files"
echo "   pre-commit clean              # Clean pre-commit cache"
echo "   pre-commit uninstall          # Remove pre-commit hooks"
echo ""
echo "💡 The hooks will now run automatically on commit!" 