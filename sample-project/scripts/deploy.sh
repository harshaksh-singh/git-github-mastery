#!/usr/bin/env bash
# Simulated deployment. It deploys nothing: it prints what a real deployment would do and where.
#
#   bash scripts/deploy.sh <environment> [artifact-directory]
#
# <environment> is "staging" or "production". The optional directory (default: dist) is searched
# for the build outputs that would be deployed. On GitHub Actions the script also reports the
# commit and ref of the run, read from the default environment variables GITHUB_SHA and GITHUB_REF.
set -euo pipefail

environment="${1:-}"
artifact_dir="${2:-dist}"

case "$environment" in
  staging)    target="https://staging.inventory.example.com" ;;
  production) target="https://inventory.example.com" ;;
  "")         echo "usage: deploy.sh <staging|production> [artifact-directory]" >&2; exit 2 ;;
  *)          echo "deploy.sh: unknown environment '$environment' (expected staging or production)" >&2; exit 2 ;;
esac

echo "Simulated deployment of inventory-api"
echo "  environment : $environment"
echo "  target      : $target"
echo "  commit      : ${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
echo "  ref         : ${GITHUB_REF:-local}"

if [ -d "$artifact_dir" ] && [ -n "$(ls -A "$artifact_dir")" ]; then
  echo "  artifacts   :"
  for f in "$artifact_dir"/*; do
    echo "    - $(basename "$f")"
  done
else
  echo "deploy.sh: no build outputs in '$artifact_dir'; nothing to deploy" >&2
  exit 1
fi

echo "Nothing was changed anywhere. A real script would now upload the artifacts to $target."
