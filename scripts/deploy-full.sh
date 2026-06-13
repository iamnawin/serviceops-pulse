#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

ORG_ALIAS=${1:-ServiceCloud}

echo "Deploying full metadata to org: $ORG_ALIAS"

sf project deploy start \
  --target-org "$ORG_ALIAS" \
  --manifest manifest/package-full.xml \
  --verbose
