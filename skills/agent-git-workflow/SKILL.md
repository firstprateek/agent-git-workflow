---
name: agent-git-workflow
description: Lets coding agents land changes on GitHub on their own. Every change goes through a pull request with proof and an adversarial review by a fresh agent, then auto-merges. Changes to critical "root" paths (core design, interfaces, data, security, dependencies, CI) also need the owner to approve a one-page decision record instead of reading the code. Use when shipping, landing or merging a change in a repo whose AGENTS.md has an "Agent git workflow" section, when asked to set this workflow up, or when recording a key design decision.
license: MIT
compatibility: Needs git, jq and the GitHub CLI (gh) signed in as the repo owner with the repo and workflow scopes. GitHub repositories only. Rulesets on private repos need a paid GitHub plan.
metadata:
  version: "0.4.0"
---

# Agent git workflow

Agents land changes without waiting on the owner. The owner only approves changes near the root of the
code tree, and approves them by reading a short decision record, not the code.

## Setup

**Asked to set it up?** Follow [references/setup.md](references/setup.md).

**Otherwise**, look for a `## Agent git workflow` section in AGENTS.md.
- **No section:** the repo isn't set up. Tell the user, and open an ordinary PR.
- **Section present:** it gives you:
  - `check`: the command that proves a change works;
  - `proof`: what evidence a PR must show;
  - `core`: `paths` (root paths are in CODEOWNERS) or `none` (nothing needs the owner's approval);
  - `owner`: the owner's login. Agents act on GitHub as the owner; the owner approves a root PR by adding
    the `owner-approved` label.

## Land a change

1. **Branch from the latest default branch:**
   `git fetch origin && git switch -c <type>/<slug> --no-track origin/<default>`
   - One task per branch.
   - Parallel agents each use their own worktree (`git worktree add -b <branch> <dir> origin/<default>`)
     and pick tasks that don't touch the same files.
2. **Build and prove.** Make the change and run `check` until it passes. Collect the `proof`:
   - screenshots, for UI;
   - a transcript, for a CLI;
   - request and response, for an API;
   - before and after numbers, for performance;
   - test output, otherwise.

   For images, `scripts/evidence.sh <files>` uploads them and prints Markdown.
3. **Classify.** If `core` is `none`, the change is leaf, unless the owner asked to approve this change;
   then it is root. Otherwise, `scripts/tier.sh` prints `root` or `leaf` and the files that matched root paths. The
   change is also **root**, whatever its paths, if it:
   - changes a public interface: API, CLI flags, exported types, config keys, events;
   - changes a data model, schema, migration, or a stored or wire format;
   - touches auth, permissions, secrets or security settings;
   - adds, upgrades or removes a dependency;
   - changes CI, build, release or deploy;
   - deletes or renames a module, or refactors across modules;
   - is hard to undo once merged or released.

   When unsure, it is root.
4. **Root only: write the decision record.** Fill in [assets/decision-record.md](assets/decision-record.md)
   as `docs/decisions/<YYYY-MM-DD>-<slug>.md`. The owner may approve from this page alone. Before
   changing an area, read the records that cover it, and don't reopen a decision without new facts.
5. **Open the PR.**
   - **Body:** what changed and why; the tier with its reason; the proof; the record's path if root.
     When fixing a bug whose cause you found, add a line `Regressed-by: #<n>`.
   - **Command:** `gh pr create --title "<title>" --body-file <file> --label tier:<root|leaf>`
6. **Get a fresh review.** Start a reviewer with no context from your work: a sub-agent, or a separate
   headless session. Give it [references/review.md](references/review.md), the PR number and this
   skill's folder path, but not your reasoning.
   - Fix what holds up, and reply in the PR to what you reject.
   - If the reviewer says root, relabel the PR, add the record, and get another review.
   - After 3 rounds that still leave blocking findings, ask the owner.
7. **Merge.**
   - **Leaf:** `gh pr merge <n> --auto --squash --delete-branch`. It merges once the required checks
     pass. If a check fails, fix it and push.
   - **Root:** `agent-gate` stays red until the owner approves. That is expected, so don't try to fix it,
     and move on to other work.
     - Queue `--auto` only if the repo's `agent-git-workflow` ruleset is active (check with
       `gh api repos/{owner}/{repo}/rulesets --jq '.[].name'`). Without the ruleset, `--auto` would merge
       at once. Instead, merge after `gh pr checks <n>` shows `agent-gate` passing.
     - Pushing after approval makes the approval stale, so avoid it. If you must push, say what changed in
       a PR comment.
8. **After merge**, check the result where it lands (a deploy URL or a released package) if the repo has
   one, and close the issue. Every 20 merged PRs or so, and whenever the owner requested changes on a
   root PR, follow [references/learn.md](references/learn.md).

## When you need the owner

Decide reversible choices yourself and note them in the PR. For anything the repo, its decision records
and the task can't answer:
1. Comment on the issue or PR with the question, the options, your recommendation, and the default
   you'll take.
2. Add the `needs-owner` label.
3. Work on something else.

Write a decision record when the owner decides something in conversation that constrains later work.

## Never

- Push or force-push to the default branch, or bypass a ruleset.
- Add `owner-approved`, or remove it. Only the owner does that, by hand. You act as the owner on GitHub,
  so nothing technical stops you: this rule is the whole lock.
- Weaken `agent-gate`, CODEOWNERS or a ruleset outside a root PR.
- Put secrets, personal data or private hostnames in proof. On a public repo, proof is public for good.
