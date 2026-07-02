#!/usr/bin/env bash
#
# install.sh - Deploy CI hail assets.
#
# This script lives inside isaac-ci/ so the payload is self-contained.
# It installs:
#   1. config/hail/ci-failure.md -> target Isaac root
#   2. github/workflows/ci-failure-hail.yml -> a chosen GitHub repo checkout
#
# Usage:
#   ./isaac-ci/install.sh --repo /path/to/repo
#   ./isaac-ci/install.sh --repo /path/to/repo --dry-run
#   ./isaac-ci/install.sh --band-only
#
# The remote host/user/isaac-root come from ../.env. The workflow target repo
# may come from --repo, CI_REPO_DIR, or "ci-repo-dir:" in ../.env.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Copy ../.env.example to ../.env and populate host/user values."
  exit 1
fi

HOST=$(grep -E '^host:' "$ENV_FILE" | cut -d: -f2- | xargs || true)
USER=$(grep -E '^user:' "$ENV_FILE" | cut -d: -f2- | xargs || true)

if [[ -z "$HOST" || -z "$USER" ]]; then
  echo "ERROR: Could not parse 'host:' and 'user:' from $ENV_FILE"
  exit 1
fi

TARGET="${USER}@${HOST}"

ISAAC_ROOT=${ISAAC_ROOT:-}
if [[ -z "$ISAAC_ROOT" ]]; then
  ISAAC_ROOT=$(grep -E '^isaac-root:' "$ENV_FILE" | cut -d: -f2- | xargs || true)
fi
if [[ -z "$ISAAC_ROOT" ]]; then
  ISAAC_ROOT="~/.isaac"
fi

CI_REPO_DIR=${CI_REPO_DIR:-}
if [[ -z "$CI_REPO_DIR" ]]; then
  CI_REPO_DIR=$(grep -E '^ci-repo-dir:' "$ENV_FILE" | cut -d: -f2- | xargs || true)
fi

DRY_RUN=""
BAND_ONLY="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      CI_REPO_DIR="${2:-}"
      shift 2
      ;;
    --band-only)
      BAND_ONLY="true"
      shift
      ;;
    -n|--dry-run)
      DRY_RUN="-n"
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: ./isaac-ci/install.sh [--repo /path/to/repo] [--band-only] [--dry-run]"
      exit 1
      ;;
  esac
done

echo "==> Installing isaac-ci from ${SCRIPT_DIR}"
echo "    Isaac target: ${TARGET}:${ISAAC_ROOT}"
if [[ "$BAND_ONLY" != "true" ]]; then
  echo "    Workflow repo: ${CI_REPO_DIR:-<unset>}"
fi
echo "    (only copies/updates files; does NOT delete anything)"
[[ -n "$DRY_RUN" ]] && echo "    [dry-run mode]"
echo

if [[ "$HOST" == "localhost" || "$HOST" == "127.0.0.1" || "$HOST" == "$(hostname -s 2>/dev/null || hostname)" ]]; then
  DEST_BASE="${HOME}/.isaac"
  mkdir -p "${DEST_BASE}/config/hail"
  echo "Copying CI hail band locally ..."
  rsync -av ${DRY_RUN} \
    "${SCRIPT_DIR}/config/hail/" \
    "${DEST_BASE}/config/hail/"
else
  echo "Copying CI hail band remotely ..."
  rsync -av ${DRY_RUN} -e ssh \
    "${SCRIPT_DIR}/config/hail/" \
    "${TARGET}:${ISAAC_ROOT}/config/hail/"
fi

if [[ "$BAND_ONLY" != "true" ]]; then
  if [[ -z "$CI_REPO_DIR" ]]; then
    echo
    echo "ERROR: No workflow target repo configured."
    echo "Set ci-repo-dir: in ../.env or pass --repo /path/to/repo"
    exit 1
  fi
  if [[ ! -d "$CI_REPO_DIR/.git" ]]; then
    echo
    echo "ERROR: $CI_REPO_DIR does not look like a git checkout."
    exit 1
  fi

  mkdir -p "${CI_REPO_DIR}/.github/workflows"
  echo "Copying workflow into ${CI_REPO_DIR}/.github/workflows/ ..."
  rsync -av ${DRY_RUN} \
    "${SCRIPT_DIR}/github/workflows/ci-failure-hail.yml" \
    "${CI_REPO_DIR}/.github/workflows/"
fi

echo
echo "Install complete."
echo "Next steps:"
echo "  - configure vars.ISAAC_HAIL_URL in the target GitHub repo"
echo "  - configure secrets.ISAAC_SERVER_AUTH_TOKEN in the target GitHub repo"
echo "  - reload/restart the relevant Isaac sessions on the target"
