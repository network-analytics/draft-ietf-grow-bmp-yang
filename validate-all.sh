#!/bin/bash
set -e

echo "Validating yang modes"

PYANG_INPUT='ietf-bmp.yang  ietf-bmp-tcp-dependencies.yang'
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
YANG_PATH="${YANG_PATH:-$SCRIPT_DIR/../other_examples/yang/experimental/ietf-extracted-YANG-modules}"

pyang --ietf --max-line-length 69 --yang-line-length=69 -p . -p "$YANG_PATH" $PYANG_INPUT

# Compare
for orig in $PYANG_INPUT; do
  pyang --ietf --max-line-length 69 -p . -p "$YANG_PATH" -f yang --yang-canonical "$orig" > /tmp/canonical.yang
  if ! diff -q "$orig" /tmp/canonical.yang; then
    echo "ERROR: $orig is not canonical. Run: pyang -f yang --yang-canonical -o \"$orig\" \"$orig\""
    exit 1
  fi
done

yanglint -p . -p "$YANG_PATH" ietf-bmp.yang ietf-bmp-tcp-dependencies.yang -f yang > /dev/null

