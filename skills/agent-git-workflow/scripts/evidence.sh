#!/usr/bin/env bash
# Upload proof files (screenshots, logs) to the orphan branch `agent-evidence`, in a folder named after the
# current branch, without touching the working tree or the index. Prints Markdown links to paste into the
# PR. Links use the commit SHA, so they never change. On a public repo the files are public for good.
#
# Usage: evidence.sh <file>...
# Env:   EVIDENCE_REMOTE (default origin), EVIDENCE_FOLDER (default: current branch, "/" -> "-")
set -euo pipefail

[ $# -gt 0 ] || { echo "usage: evidence.sh <file>..." >&2; exit 2; }
seen=" "
for f in "$@"; do
  [ -f "$f" ] || { echo "evidence.sh: no such file: $f" >&2; exit 2; }
  n=$(basename "$f")
  case "$seen" in *" $n "*) echo "evidence.sh: two files named $n" >&2; exit 2 ;; esac
  seen="$seen$n "
done

remote=${EVIDENCE_REMOTE:-origin}
branch=agent-evidence
folder=${EVIDENCE_FOLDER:-$(git rev-parse --abbrev-ref HEAD | tr '/' '-')}
[ "$folder" != HEAD ] || { echo "evidence.sh: detached HEAD; set EVIDENCE_FOLDER" >&2; exit 2; }
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

idx=$(mktemp)
trap 'rm -f "$idx"' EXIT

for attempt in 1 2 3 4 5 6; do
  parent=""
  if git fetch -q "$remote" "+refs/heads/$branch:refs/remotes/$remote/$branch" 2>/dev/null; then
    parent=$(git rev-parse "refs/remotes/$remote/$branch")
  fi
  rm -f "$idx"
  if [ -n "$parent" ]; then GIT_INDEX_FILE=$idx git read-tree "$parent"; else GIT_INDEX_FILE=$idx git read-tree --empty; fi
  for f in "$@"; do
    blob=$(git hash-object -w "$f")
    GIT_INDEX_FILE=$idx git update-index --add --cacheinfo "100644,$blob,$folder/$(basename "$f")"
  done
  tree=$(GIT_INDEX_FILE=$idx git write-tree)
  if [ -n "$parent" ]; then
    commit=$(git commit-tree "$tree" -p "$parent" -m "evidence: $folder")
  else
    commit=$(git commit-tree "$tree" -m "evidence: $folder")
  fi
  if git push -q "$remote" "$commit:refs/heads/$branch" 2>/dev/null; then
    for f in "$@"; do
      n=$(basename "$f")
      url="https://github.com/$repo/blob/$commit/$folder/$(printf '%s' "$n" | sed 's/%/%25/g; s/ /%20/g; s/(/%28/g; s/)/%29/g')?raw=true"
      case "$n" in
        *.png | *.jpg | *.jpeg | *.gif | *.webp | *.svg) echo "![$n]($url)" ;;
        *) echo "[$n]($url)" ;;
      esac
    done
    exit 0
  fi
  sleep $((attempt + RANDOM % 3))
done
echo "evidence.sh: couldn't push to $remote/$branch (busy, or a ruleset blocks new branches)" >&2
exit 1
