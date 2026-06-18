#!/usr/bin/env bash
set -euo pipefail

# Build script for hlsdk-portable with VGUI enabled
# - Initializes submodules
# - Configures CMake with USE_VGUI=ON
# - Builds client-only (adjust BUILD_SERVER as needed)
# - Copies vgui.so into build output directories for runtime

# Usage: ./scripts/build_with_vgui.sh [build-dir]
# Default build-dir: build-vgui

BUILD_DIR=${1:-build-vgui}
CMAKE_GENERATOR=${CMAKE_GENERATOR:-}
JOBS=${JOBS:-$(nproc)}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

echo "Initializing submodules (vgui_support)..."
git submodule update --init --recursive

echo "Configuring CMake (USE_VGUI=ON) into ${BUILD_DIR}..."
if [ -n "$CMAKE_GENERATOR" ]; then
  cmake -S . -B "$BUILD_DIR" -DUSE_VGUI=ON -DBUILD_CLIENT=ON -DBUILD_SERVER=OFF -G "$CMAKE_GENERATOR"
else
  cmake -S . -B "$BUILD_DIR" -DUSE_VGUI=ON -DBUILD_CLIENT=ON -DBUILD_SERVER=OFF
fi

echo "Building (jobs=${JOBS})..."
cmake --build "$BUILD_DIR" -j"${JOBS}"

# Copy vgui runtime into build outputs for convenience (matches CI behavior)
VGUI_LIB_SRC="${ROOT_DIR}/vgui_support/vgui-dev/lib/vgui.so"
if [ -f "$VGUI_LIB_SRC" ]; then
  echo "Copying vgui.so into ${BUILD_DIR} and ${BUILD_DIR}/cl_dll..."
  cp -v "$VGUI_LIB_SRC" "$BUILD_DIR/"
  mkdir -p "$BUILD_DIR/cl_dll"
  cp -v "$VGUI_LIB_SRC" "$BUILD_DIR/cl_dll/"
  echo "You can also set LD_LIBRARY_PATH=$BUILD_DIR/cl_dll to run the client without copying." 
else
  echo "Warning: vgui.so not found at $VGUI_LIB_SRC"
  echo "Make sure vgui_support submodule was initialized and built (see README)."
fi

echo "Build complete. Output: ${BUILD_DIR}/cl_dll/client.so"
