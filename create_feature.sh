#!/bin/bash
set -euo pipefail

FEATURE_NAME=${1:-}

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $(basename "$0") NN_name  (e.g. 06_mytool)" >&2
  exit 1
fi

# Always operate from the repo root, regardless of where the script is invoked from
cd "$(dirname "$0")"

if [[ ! "$FEATURE_NAME" =~ ^[0-9]{2}_[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "Error: feature name must match NN_name (two-digit order, underscore, lowercase name)" >&2
  echo "Example: $(basename "$0") 06_mytool" >&2
  exit 1
fi

# Check if ./features/${FEATURE_NAME} exists
if [ ! -d "./features/$FEATURE_NAME" ]; then
  echo "Creating ./features/$FEATURE_NAME directory..."
  mkdir -p "./features/$FEATURE_NAME"
else
  echo "Feature already exists"
  exit 1
fi

rsync -avP ./templates/feature/ ./features/${FEATURE_NAME}/
chmod +x "./features/${FEATURE_NAME}/install.sh"

echo
echo "Done. Next steps:"
echo "  1. Fill in features/$FEATURE_NAME/install.sh (idempotency gate + install logic)"
echo "  2. Add a check_command_version branch for the new tool in features/utils.sh"
echo "  3. Verify with: make build && make test-fedora"
