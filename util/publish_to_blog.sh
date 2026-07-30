#!/usr/bin/env bash
set -e

DEST_DIR="/home/daniel/pro/blog/public/img/loopspeed"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$DEST_DIR"

echo "Copying generated plots to blog public directory ($DEST_DIR)..."

cp "$SRC_DIR"/inc_inc.*.png "$DEST_DIR"/
cp "$SRC_DIR"/speed.png "$DEST_DIR"/
cp "$SRC_DIR"/speed2.png "$DEST_DIR"/
cp "$SRC_DIR"/diff_loop.png "$DEST_DIR"/
cp "$SRC_DIR"/loop_type.png "$DEST_DIR"/
cp "$SRC_DIR"/compilation.png "$DEST_DIR"/
cp "$SRC_DIR"/compilation_table.png "$DEST_DIR"/
cp "$SRC_DIR"/cpp_optimization.png "$DEST_DIR"/
cp "$SRC_DIR"/cpp_optimization_table.png "$DEST_DIR"/
cp "$SRC_DIR"/f_optimization.png "$DEST_DIR"/
cp "$SRC_DIR"/f_optimization_table.png "$DEST_DIR"/
cp "$SRC_DIR"/pairedHistogramTiming.png "$DEST_DIR"/

echo "All plots successfully published to blog."
