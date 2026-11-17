#!/usr/bin/env bash
# Classify the current change by path, the same way agent-gate does: prints "root" or "leaf", then each
# changed file that matches a root path, with the pattern it matched.
#
# Usage: tier.sh [base-ref]     (default: origin/<default branch>)
#
# Changed files = everything that differs from the merge base, committed or not, plus untracked files.
# Root paths = CODEOWNERS lines with an owner (read from the base ref; last match wins, a line with no
# owner removes ownership, "dir/*" covers direct children only), plus .github/, docs/decisions/ and
# CODEOWNERS itself. Each pattern is tested on its own with git's matcher in an empty repo.
set -euo pipefail

base=${1:-}
if [ -z "$base" ]; then
  def=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  [ -n "$def" ] || def=origin/$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
  base=$def
fi
mb=$(git merge-base "$base" HEAD) || { echo "tier.sh: no merge base with $base (fetch first?)" >&2; exit 2; }

co=""
for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
  if co=$(git show "$base:$p" 2>/dev/null); then break; fi
  co=""
done

paths=$({ git -c core.quotePath=false diff --name-only --no-renames "$mb"
  git -c core.quotePath=false ls-files --others --exclude-standard; } | sort -u)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q

matches=$(
  { printf '%s\n' "$co" | awk '{ sub(/[[:space:]]+#.*/, "") } !/^[[:space:]]*(#|$)/ { print (NF > 1) " " $1 }'
    printf '1 %s\n' /.github/ /docs/decisions/ /CODEOWNERS /docs/CODEOWNERS; } |
    while read -r owned p; do
      printf '%s\n' "$p" >"$tmp/pat"
      printf '%s\n' "$paths" |
        git -C "$tmp" -c core.excludesFile="$tmp/pat" -c core.quotePath=false check-ignore --no-index --stdin |
        awk -v o="$owned" -v p="$p" '
          BEGIN { star = (p ~ /\/\*$/); pre = p; sub(/^\//, "", pre); sub(/\*$/, "", pre) }
          { if (star && index($0, pre) == 1 && index(substr($0, length(pre) + 1), "/")) next
            print $0 "\t" o "\t" p }' || true
    done |
    awk -F'\t' '{ last[$1] = $2 "\t" $3 } END { for (f in last) { split(last[f], a, "\t"); if (a[1] == 1) print f "\t" a[2] } }' |
    sort
)

if [ -n "$matches" ]; then
  echo "root"
  printf '%s\n' "$matches"
else
  echo "leaf"
  [ -n "$co" ] || echo "(no CODEOWNERS on $base: only built-in root paths apply)"
fi
