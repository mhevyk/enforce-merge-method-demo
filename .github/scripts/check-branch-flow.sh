#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:?BASE_REF argument is required}"
HEAD_REF="${2:?HEAD_REF argument is required}"

# Allowed transitions: source|target|method
#   source, target — branch glob patterns
#   method         — merge | squash
ALLOWED_PAIRS=(
  "release/*   |main       |merge"
  "hotfix/*    |main       |merge"
  "main        |development|merge"
  "feat/*      |development|squash"
  "bugfix/*    |development|squash"
  "chore/*     |development|squash"
  "refactor/*  |development|squash"
  "hotfix/*    |development|squash"
)

method_label() {
  case "$1" in
    merge)  echo "Create a merge commit" ;;
    squash) echo "Squash and merge" ;;
    *)      echo "$1" ;;
  esac
}

# Split a pair string into source, target, and method variables (trims surrounding whitespace)
parse_pair() {
  local pair="$1"
  IFS='|' read -r source target method <<< "$pair"
  source="${source//[[:space:]]/}"
  target="${target//[[:space:]]/}"
  method="${method//[[:space:]]/}"
}

print_allowed_pairs() {
  local pair source target method
  printf "  %-12s  %-12s  %s\n" "SOURCE" "TARGET" "METHOD"
  printf "  %-12s  %-12s  %s\n" "------" "------" "------"
  for pair in "${ALLOWED_PAIRS[@]}"; do
    parse_pair "$pair"
    printf "  %-12s  %-12s  %s\n" "$source" "$target" "$(method_label "$method")"
  done
}

echo "::group::Branch flow check"
echo "Checking transition: $HEAD_REF -> $BASE_REF"
echo

for pair in "${ALLOWED_PAIRS[@]}"; do
  parse_pair "$pair"

  # shellcheck disable=SC2053 # Intentional: source/target are glob patterns
  if [[ "$HEAD_REF" == $source && "$BASE_REF" == $target ]]; then
    case "$method" in
      merge | squash)
        echo "✔ Allowed: $source -> $target"
        echo "  Merge method: $(method_label "$method")"
        if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
          echo "method=$method" >> "$GITHUB_OUTPUT"
          echo "label=$(method_label "$method")" >> "$GITHUB_OUTPUT"
        fi
        echo "::endgroup::"
        exit 0
        ;;
      *)
        echo "::error::Unknown method '$method' for pair $source -> $target"
        echo "::endgroup::"
        exit 1
        ;;
    esac
  fi
done

echo "::error::Forbidden transition: $HEAD_REF -> $BASE_REF"
echo "Allowed transitions:"
echo
print_allowed_pairs
echo "::endgroup::"
exit 1
