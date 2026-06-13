#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_ALIAS=${1:-ServiceCloud}

bash "$SCRIPT_DIR/deploy-core.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/deploy-code.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/deploy-flexipages.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/deploy-ui.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/deploy-app.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/deploy-security.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-full.sh" "$ORG_ALIAS"

echo "All layers deployed and final validation passed."
