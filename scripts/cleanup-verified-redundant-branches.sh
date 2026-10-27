#!/usr/bin/env bash
set -euo pipefail
# Manual cleanup only. Default is dry-run. Requires gh CLI and jq.
repo='THETECHYSASQUATCH/CarDSP'
default_branch='development/phase_one'
candidates=('main_fullbackup')
for branch in "${candidates[@]}"; do
  if [[ "$branch" == "$default_branch" ]]; then echo "[ERROR] Protected default branch"; exit 1; fi
  encoded=$(jq -nr --arg value "$branch" '$value|@uri')
  ahead=$(gh api "repos/$repo/compare/$default_branch...$encoded" --jq '.ahead_by')
  if [[ "$ahead" != 0 ]]; then echo "[ERROR] Unique commits on $branch"; exit 1; fi
  open_prs=$(gh api --paginate "repos/$repo/pulls?state=open&per_page=100" --jq ".[] | select(.head.ref == \"$branch\" and .head.repo.full_name == \"$repo\") | .number" | wc -l | tr -d ' ')
  if [[ "$open_prs" != 0 ]]; then echo "[ERROR] Open pull request for $branch"; exit 1; fi
  if [[ "${1:-}" == "--execute" ]]; then
    gh api -X DELETE "repos/$repo/git/refs/heads/$encoded"
    echo "[OK] Deleted $branch"
  else
    echo "[OK] DRY RUN: eligible $branch"
  fi
done
