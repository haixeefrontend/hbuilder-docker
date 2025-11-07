#!/bin/bash
set -e

echo "🚀 Starting HBuilderX in background..."

/opt/hbuilderx/HBuilderX > /var/log/hbuilderx.log 2>&1 &

echo "✅ HBuilderX started."

if [ "$#" -gt 0 ]; then exec "$@"; else exec bash; fi
