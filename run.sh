#!/usr/bin/env bash
# Quick setup & run script for macOS
# Usage: ./run.sh [ios|android|macos]

set -e

PLATFORM=${1:-ios}

echo ""
echo "AI Scheduler — Flutter run script"
echo "=================================="
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found. Install it:"
  echo "  brew install --cask flutter"
  echo "  flutter doctor"
  exit 1
fi

# Check for credentials
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON" ]; then
  echo "⚠  Supabase credentials not set."
  echo ""
  echo "   To use authentication, export your credentials first:"
  echo "   export SUPABASE_URL=https://your-project.supabase.co"
  echo "   export SUPABASE_ANON=your-anon-key"
  echo ""
  echo "   Get a free project at https://supabase.com"
  echo ""
  echo "   Running without auth (app will start, but sign-in will fail)..."
  echo ""
fi

# Install dependencies
echo "Installing Flutter packages..."
flutter pub get

echo ""
echo "Running on $PLATFORM..."
echo ""

flutter run \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON="${SUPABASE_ANON:-}" \
  -d "$PLATFORM"
