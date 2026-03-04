#!/bin/bash

# Quick Flutter run script that avoids VM timeout issues
echo "🧹 Cleaning up stuck processes..."
pkill -f "dart.*debug" 2>/dev/null || true
pkill -f "flutter.*debug" 2>/dev/null || true

echo "🚀 Running Flutter with uninstall-first..."
fvm flutter run --uninstall-first
