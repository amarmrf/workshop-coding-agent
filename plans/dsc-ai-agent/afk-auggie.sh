#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

plan_dir="$(cd "$(dirname "$0")" && pwd)"
target_repo="/Users/amarmaruf/work/myka/dsc-ai-agent"

mkdir -p "$plan_dir/artifacts"

base_prompt="$(cat "$plan_dir/prompt.md")"

for ((i = 1; i <= $1; i++)); do
  timestamp="$(date +"%Y%m%d-%H%M%S")"
  prompt_file="$(mktemp)"
  json_file="$(mktemp)"
  artifact="$plan_dir/artifacts/auggie-iteration-${i}-${timestamp}.json"
  trap 'rm -f "$prompt_file" "$json_file"' EXIT

  ralph_commits="$(
    git -C "$target_repo" log --grep="^RALPH:" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || true
  )"

  cat > "$prompt_file" <<EOF
$base_prompt

Previous RALPH commits in the target repo:
${ralph_commits:-No RALPH commits found.}
EOF

  echo "---- Auggie iteration $i ----"

  auggie \
    --print \
    --quiet \
    --output-format json \
    --workspace-root "$target_repo" \
    --instruction-file "$prompt_file" | tee "$artifact" > "$json_file"

  result="$(jq -r '.result // ""' "$json_file")"

  if [[ "$result" == *"<promise>ABORT</promise>"* ]]; then
    echo "Auggie aborted on iteration $i. See $artifact."
    exit 1
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi

  rm -f "$prompt_file" "$json_file"
  trap - EXIT
done
