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
  artifact="$plan_dir/artifacts/codex-iteration-${i}-${timestamp}.txt"
  result_file="$(mktemp)"
  trap 'rm -f "$result_file"' EXIT

  ralph_commits="$(
    git -C "$target_repo" log --grep="^RALPH:" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || true
  )"

  prompt="$(cat <<EOF
$base_prompt

Previous RALPH commits in the target repo:
${ralph_commits:-No RALPH commits found.}
EOF
)"

  echo "---- Codex iteration $i ----"

  codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$target_repo" \
    -o "$result_file" \
    "$prompt" | tee "$artifact"

  result="$(cat "$result_file")"

  if [[ "$result" == *"<promise>ABORT</promise>"* ]]; then
    echo "Codex aborted on iteration $i. See $artifact."
    exit 1
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi

  rm -f "$result_file"
  trap - EXIT
done
