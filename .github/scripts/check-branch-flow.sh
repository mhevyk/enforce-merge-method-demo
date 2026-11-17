#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:?BASE_REF argument is required}"
HEAD_REF="${2:?HEAD_REF argument is required}"

# Дозволені джерела для main (тільки Merge commit)
MAIN_ALLOWED_SOURCES=(
  "release/*"
  "hotfix/*"
)

# Джерела для development, які мають мерджитись через Merge commit (бекмердж)
DEV_MERGE_COMMIT_SOURCES=(
  "main"
)

# Дозволені джерела для development через Squash and merge
DEV_SQUASH_SOURCES=(
  "feat/*"
  "feature/*"
  "bugfix/*"
  "fix/*"
  "chore/*"
  "refactor/*"
  "hotfix/*"
)

matches_any() {
  local ref="$1"
  shift
  local patterns=("$@")

  for pattern in "${patterns[@]}"; do
    if [[ "$ref" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

case "$BASE_REF" in
  main)
    if ! matches_any "$HEAD_REF" "${MAIN_ALLOWED_SOURCES[@]}"; then
      echo "::error::Заборонений перехід ($HEAD_REF -> main). Дозволені лише: ${MAIN_ALLOWED_SOURCES[*]}"
      exit 1
    fi
    echo "OK ($HEAD_REF -> main): Використовуйте 'Create a merge commit'."
    ;;

  development)
    if matches_any "$HEAD_REF" "${DEV_MERGE_COMMIT_SOURCES[@]}"; then
      echo "OK Backmerge ($HEAD_REF -> development): Використовуйте 'Create a merge commit'."
    elif matches_any "$HEAD_REF" "${DEV_SQUASH_SOURCES[@]}"; then
      echo "OK Feature/Fix ($HEAD_REF -> development): Використовуйте 'Squash and merge'."
    else
      echo "::error::Заборонений перехід ($HEAD_REF -> development). Дозволені: ${DEV_MERGE_COMMIT_SOURCES[*]} ${DEV_SQUASH_SOURCES[*]}"
      exit 1
    fi
    ;;

  *)
    echo "OK ($HEAD_REF -> $BASE_REF): Використовуйте 'Squash and merge'."
    ;;
esac