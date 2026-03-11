#!/bin/bash

set -euo pipefail

plan_dir="$(cd "$(dirname "$0")" && pwd)"
target_repo="/Users/amarmaruf/work/myka/dsc-ai-agent"
prompt_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT

base_prompt="$(cat "$plan_dir/prompt.md")"
ralph_commits="$(
  git -C "$target_repo" log --grep="^RALPH:" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || true
)"

cat > "$prompt_file" <<EOF
$base_prompt

Previous RALPH commits in the target repo:
${ralph_commits:-No RALPH commits found.}
EOF

auggie \
  --print \
  --workspace-root "$target_repo" \
  --instruction-file "$prompt_file"
