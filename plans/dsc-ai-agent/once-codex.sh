#!/bin/bash

set -euo pipefail

plan_dir="$(cd "$(dirname "$0")" && pwd)"
target_repo="/Users/amarmaruf/work/myka/dsc-ai-agent"

base_prompt="$(cat "$plan_dir/prompt.md")"
ralph_commits="$(
  git -C "$target_repo" log --grep="^RALPH:" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || true
)"

prompt="$(cat <<EOF
$base_prompt

Previous RALPH commits in the target repo:
${ralph_commits:-No RALPH commits found.}
EOF
)"

cd "$target_repo"
codex -s danger-full-access "$prompt"
