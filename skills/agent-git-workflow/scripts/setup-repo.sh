#!/usr/bin/env bash
# Apply agent-git-workflow's GitHub settings to the current repo. Needs admin on the repo.
#
#   setup-repo.sh settings <paths|none> [owner]
#                                      merge settings, labels, core and owner variables (owner defaults
#                                      to the signed-in gh user; none = nothing needs approval)
#   setup-repo.sh ruleset [check...]   protect the default branch, requiring agent-gate plus each named CI
#                                      check (only checks that run on every PR). Run after agent-gate.yml
#                                      is on the default branch.
set -euo pipefail

usage() { sed -n '2,9p' "$0" >&2; exit 2; }
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

case "${1:-}" in
settings)
  core=${2:-}
  case "$core" in paths | none) ;; *) usage ;; esac
  owner=${3:-$(gh api user --jq .login)}
  gh api -X PATCH "repos/$repo" --silent \
    -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
    -F allow_auto_merge=true -F delete_branch_on_merge=true -F allow_update_branch=true \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY
  gh label create tier:root --color B60205 --description "Needs the owner's approval of a decision record" --force -R "$repo"
  gh label create tier:leaf --color 0E8A16 --description "Merges after review and green checks" --force -R "$repo"
  gh label create needs-owner --color FBCA04 --description "An agent is waiting for the owner's answer" --force -R "$repo"
  gh label create owner-approved --color 5319E7 --description "The owner approved the decision record. Owner only." --force -R "$repo"
  gh variable set AGENT_GIT_WORKFLOW_OWNER --body "$owner" -R "$repo"
  gh variable set AGENT_GIT_WORKFLOW_CORE --body "$core" -R "$repo"
  echo "settings applied to $repo (core $core, owner $owner)"
  ;;
ruleset)
  shift
  # No bypass: agents act as the owner, so a bypass would be theirs too. Disable the ruleset by hand in an
  # emergency. integration_id 15368 = GitHub Actions, so only a real workflow run satisfies a check.
  body=$(jq -n '
    {name: "agent-git-workflow", target: "branch", enforcement: "active",
     conditions: {ref_name: {include: ["~DEFAULT_BRANCH"], exclude: []}},
     bypass_actors: [],
     rules: [{type: "deletion"}, {type: "non_fast_forward"},
       {type: "pull_request", parameters: {required_approving_review_count: 0,
         require_code_owner_review: false, dismiss_stale_reviews_on_push: false,
         require_last_push_approval: false, required_review_thread_resolution: false}},
       {type: "required_status_checks", parameters: {strict_required_status_checks_policy: false,
         required_status_checks: ([{context: "agent-gate"}] + ($ARGS.positional | map({context: .}))
           | map(. + {integration_id: 15368}))}}]}' --args "$@")
  id=$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "agent-git-workflow") | .id')
  if [ -n "$id" ]; then
    printf '%s' "$body" | gh api -X PUT "repos/$repo/rulesets/$id" --input - --silent
  else
    printf '%s' "$body" | gh api -X POST "repos/$repo/rulesets" --input - --silent
  fi
  echo "ruleset active on $repo (required checks: agent-gate $*)"
  ;;
*) usage ;;
esac
