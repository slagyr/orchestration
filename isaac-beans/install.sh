#!/usr/bin/env bash
#
# install.sh - Deploy the isaac-beans (prompts + hail config) to an Isaac root.
#
# This script lives inside isaac-beans/ so the payload is self-contained.
#
# Behavior: ONLY copies/overwrites the config/ and prompts/ trees.
# It will NEVER delete files or directories on the target.
#
# Usage (run from the orchestration checkout root):
#   ./isaac-beans/install.sh              # normal sync
#   ./isaac-beans/install.sh --dry-run    # or -n : show what would happen
#
# Requirements:
#   - .env present in the parent directory (orchestration checkout root, git-ignored).
#     Populate from .env.example.
#   - SSH access to the target (key-based auth recommended; same pattern as
#     verification in happy-path.md).
#
# The script re-uses the same .env (host: / user:) established for running
# the happy-path verification. The real hostname is never in this script
# or any committed file.
#
# Target layout (copies the relevant subdirectories from isaac-beans/):
#   <isaac-root>/config/hail/   <-- from isaac-beans/config/hail/
#   <isaac-root>/prompts/       <-- from isaac-beans/prompts/
#
# Default isaac-root on target: ~/.isaac
#
# After running, you may need to restart/reload the affected Isaac sessions
# or daemons on the target machine so the new prompts/skills/bands are picked up.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Make sure you are running from the orchestration checkout root, or that .env exists next to the isaac-beans/ directory."
  echo "Copy .env.example to .env and edit the host/user values."
  exit 1
fi

# Parse the same .env format used by verification steps.
HOST=$(grep -E '^host:' "$ENV_FILE" | cut -d: -f2- | xargs || true)
USER=$(grep -E '^user:' "$ENV_FILE" | cut -d: -f2- | xargs || true)

if [[ -z "$HOST" || -z "$USER" ]]; then
  echo "ERROR: Could not parse 'host:' and 'user:' from $ENV_FILE"
  exit 1
fi

TARGET="${USER}@${HOST}"

# Optional override via env or .env (isaac-root: ...)
ISAAC_ROOT=${ISAAC_ROOT:-}
if [[ -z "$ISAAC_ROOT" ]]; then
  ISAAC_ROOT=$(grep -E '^isaac-root:' "$ENV_FILE" | cut -d: -f2- | xargs || true)
fi
if [[ -z "$ISAAC_ROOT" ]]; then
  ISAAC_ROOT="~/.isaac"
fi

DRY_RUN=""
if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="-n"
  echo "[dry-run mode]"
fi

echo "==> Installing isaac-beans from ${SCRIPT_DIR}"
echo "    Target: ${TARGET}:${ISAAC_ROOT}"
echo "    (only copies/updates files; does NOT delete anything on target)"
echo

# Decide local vs remote.
# Treat obvious local hosts as direct filesystem copy (no ssh).
if [[ "$HOST" == "localhost" || "$HOST" == "127.0.0.1" || "$HOST" == "$(hostname -s 2>/dev/null || hostname)" ]]; then
  echo "Local install detected."
  DEST_BASE="${HOME}/.isaac"
  mkdir -p "${DEST_BASE}/config" "${DEST_BASE}/prompts"

  echo "Copying config/hail ..."
  rsync -av ${DRY_RUN} \
    "${SCRIPT_DIR}/config/" \
    "${DEST_BASE}/config/"

  echo "Copying prompts ..."
  rsync -av ${DRY_RUN} \
    "${SCRIPT_DIR}/prompts/" \
    "${DEST_BASE}/prompts/"

else
  echo "Remote install via ssh."

  echo "Copying config/hail ..."
  rsync -av ${DRY_RUN} -e ssh \
    "${SCRIPT_DIR}/config/" \
    "${TARGET}:${ISAAC_ROOT}/config/"

  echo "Copying prompts ..."
  rsync -av ${DRY_RUN} -e ssh \
    "${SCRIPT_DIR}/prompts/" \
    "${TARGET}:${ISAAC_ROOT}/prompts/"
fi

echo
echo "Install complete."
echo "Note: Restart or reload the relevant Isaac sessions/crews on the target"
echo "      so the updated hail bands, commands, and skills are picked up."
echo
echo "Example (on target):"
echo "  pkill -f isaac || true   # or use your launchctl / process manager"
