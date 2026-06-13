#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_ALIAS=${1:-ServiceCloud}

# NOTE: --dry-run does not persist anything, so layers 2+ only validate cleanly
# against an org where the previous layers are already deployed.
# On a fresh org, run deploy-all.sh instead (it deploys layer by layer).
bash "$SCRIPT_DIR/validate-core.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-code.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-flexipages.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-ui.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-app.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-security.sh" "$ORG_ALIAS"
bash "$SCRIPT_DIR/validate-full.sh" "$ORG_ALIAS"

echo "All validation layers passed."
