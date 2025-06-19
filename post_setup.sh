#!/usr/bin/env bash

set -e

# Needed for tests
export GSETTINGS_SCHEMA_DIR=/usr/share/glib-2.0/schemas
export GIO_EXTRA_MODULES=/usr/lib/gio/modules

echo "Cleaning build directory..."
rm -rf build
mkdir -p build

echo "Running build script..."
./build.sh

echo "Build complete. Exiting container."
exit 0
