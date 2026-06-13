#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

ORG_ALIAS=${1:-ServiceCloud}

echo "Validating security metadata against org: $ORG_ALIAS"

sf project deploy start \
  --target-org "$ORG_ALIAS" \
  --manifest manifest/package-security.xml \
  --dry-run \
  --verbose
