#!/bin/bash
set -e

echo "🚀 Starting HBuilderX in background..."

exec su-exec node /opt/hbuilderx/HBuilderX > /dev/null 2>&1 &

echo "✅ HBuilderX started."

if [ "$#" -gt 0 ]; then exec su-exec node "$@"; else exec su-exec node "bash"; fi
