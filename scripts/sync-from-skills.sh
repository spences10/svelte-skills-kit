#!/bin/bash
# Sync Svelte skills from the canonical skills repo.

set -euo pipefail

SKILLS_REPO=${SKILLS_REPO:-../skills}
SOURCE_DIR="$SKILLS_REPO"
DEST_DIR="plugins/svelte-skills/skills"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: canonical skills repo not found: $SOURCE_DIR" >&2
  echo "Set SKILLS_REPO=/path/to/skills if needed." >&2
  exit 1
fi

SKILLS=(
  ecosystem-guide
  svelte-components
  svelte-deployment
  svelte-layerchart
  svelte-runes
  svelte-styling
  svelte-template-directives
  sveltekit-data-flow
  sveltekit-remote-functions
  sveltekit-structure
)

rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

for skill in "${SKILLS[@]}"; do
  if [ ! -d "$SOURCE_DIR/$skill" ]; then
    echo "Error: missing canonical skill: $SOURCE_DIR/$skill" >&2
    exit 1
  fi
  cp -a "$SOURCE_DIR/$skill" "$DEST_DIR/$skill"
  echo "Synced $skill"
done
