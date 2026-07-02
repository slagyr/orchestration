#!/usr/bin/env bash
#
# configure-github.sh - Set CI hail GitHub Actions settings for a repo.
#
# Usage:
#   ./isaac-ci/configure-github.sh slagyr/isaac-hail
#   ./isaac-ci/configure-github.sh slagyr/isaac-hail --dry-run
#
# Reads ../.env and configures:
#   - secret   ISAAC_SERVER_AUTH_TOKEN
#   - variable ISAAC_HAIL_URL
#
# Expected .env keys:
#   HOST=zanebot.tail66e5f8.ts.net
#   AUTH_TOKEN=...
#
# Optional overrides:
#   ISAAC_HAIL_URL=https://...
#   ISAAC_SERVER_AUTH_TOKEN=...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Copy ../.env.example to ../.env and populate HOST plus token values."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

REPO=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      DRY_RUN="true"
      shift
      ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$1"
        shift
      else
        echo "Unknown argument: $1"
        echo "Usage: ./isaac-ci/configure-github.sh owner/repo [--dry-run]"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$REPO" ]]; then
  echo "ERROR: Missing target repo."
  echo "Usage: ./isaac-ci/configure-github.sh owner/repo [--dry-run]"
  exit 1
fi

HOST=${HOST:-${host:-}}
TOKEN_VALUE=${ISAAC_SERVER_AUTH_TOKEN:-${AUTH_TOKEN:-}}
HAIL_URL=${ISAAC_HAIL_URL:-}

if [[ -z "$HAIL_URL" ]]; then
  if [[ -z "$HOST" ]]; then
    echo "ERROR: Need either ISAAC_HAIL_URL= or HOST= in $ENV_FILE"
    exit 1
  fi
  HAIL_URL="https://${HOST}/hail/send"
fi

if [[ -z "$TOKEN_VALUE" ]]; then
  echo "ERROR: Need either ISAAC_SERVER_AUTH_TOKEN= or AUTH_TOKEN= in $ENV_FILE"
  exit 1
fi

echo "==> Configuring GitHub Actions settings for ${REPO}"
echo "    variable ISAAC_HAIL_URL=${HAIL_URL}"
echo "    secret   ISAAC_SERVER_AUTH_TOKEN=[hidden]"
[[ "$DRY_RUN" == "true" ]] && echo "    [dry-run mode]"
echo

if [[ "$DRY_RUN" == "true" ]]; then
  echo "gh variable set ISAAC_HAIL_URL -R ${REPO} --body ${HAIL_URL}"
  echo "gh secret set ISAAC_SERVER_AUTH_TOKEN -R ${REPO} <hidden>"
  exit 0
fi

gh variable set ISAAC_HAIL_URL -R "$REPO" --body "$HAIL_URL"
printf '%s' "$TOKEN_VALUE" | gh secret set ISAAC_SERVER_AUTH_TOKEN -R "$REPO"

echo
echo "GitHub settings updated for ${REPO}."
