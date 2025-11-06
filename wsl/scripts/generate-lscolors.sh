#!/usr/bin/env bash
# Generate LS_COLORS using vivid for eza

set -euo pipefail

# XDG config home
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
LSCOLORS_DIR="$XDG_CONFIG_HOME/lscolors"
THEME="${VIVID_THEME:-one-dark}"
OUTPUT_FILE="$LSCOLORS_DIR/$THEME.txt"

# Create directory if needed
mkdir -p "$LSCOLORS_DIR"

# Check for vivid
if ! command -v vivid >/dev/null 2>&1; then
  echo "vivid not found; skipping LS_COLORS generation" >&2
  echo "Install with mise or cargo: mise use -g cargo:vivid" >&2
  exit 0
fi

# Generate LS_COLORS
echo "Generating LS_COLORS for theme: $THEME"

if vivid generate "$THEME" > "$OUTPUT_FILE"; then
  echo "✓ Generated: $OUTPUT_FILE"
else
  echo "✗ Failed to generate LS_COLORS" >&2
  exit 1
fi
