#!/bin/bash

echo "🧪 Quick Test Suite for build.sh"
echo "================================="

# Test 1: Help
echo -n "Testing help command... "
if ./build.sh --help | grep -q "Font Self-Hosting Preparation Script"; then
    echo "✅ PASS"
else
    echo "❌ FAIL"
    exit 1
fi

# Test 2: Version
echo -n "Testing version command... "
if ./build.sh --version | grep -q "build.sh v2.0.0"; then
    echo "✅ PASS"
else
    echo "❌ FAIL"
    exit 1
fi

# Test 3: Invalid option
echo -n "Testing invalid option... "
if ./build.sh --invalid 2>/dev/null; then
    echo "❌ FAIL (should have failed)"
    exit 1
else
    echo "✅ PASS"
fi

echo "🎉 All basic tests passed!"
