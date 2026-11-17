# Setting up a repo

Do this once per repo, signed in to `gh` as the repo owner, who needs admin on the repo. Agents keep
acting as the owner afterwards.

## 1. Work out what you can yourself

- **The default branch, and the CI checks that run on every PR.** Leave out push-only and path-filtered
  workflows: a required check that never reports blocks PRs forever. To list check names:
  `gh pr checks <recent PR> --json name --jq '.[].name'`.
- **`check`.** The one command that proves a change works, from the package scripts, Makefile, justfile,
  Cargo, go, pyproject and the like. If none runs everything CI runs, add one, such as an npm `check`
  script.
- **`proof`.** What a reviewer needs to see:
  - screenshots of changed screens at a phone and a desktop width, for UI;
  - a transcript, for a CLI;
  - request and response, for an API;
  - test output, for a library.
- **Candidate root paths, 10 or fewer.** Prefer a few broad patterns over many narrow ones. Look for:
  - core modules that much of the code depends on (count importers);
  - areas where recent bug fixes cluster;
  - dependency manifests;
  - schemas and migrations;
  - auth and security code;
  - public API definitions;
  - build, release and deploy config.

  `.github/` and `docs/decisions/` are always root, so don't offer them. Patterns use CODEOWNERS
  syntax: no `!` and no `[ ]`, and `dir/*` covers direct children only.

## 2. Ask the owner one question

Ask which parts are core: changes there need the owner to approve a decision record first. Offer:

- **Nothing is core.** Every change merges after checks and a fresh review. The owner approves only the
  changes they explicitly ask to see. This is the right choice for experiments and vibe-coded projects.
- **These paths:** the candidates, each with its evidence (for example "imported by 19 files" or "3 of
  the last 5 bug fixes"). `.github/`, `docs/decisions/` and the change-type rules in the skill are then
  root too. The paths can grow later from evidence.

Decide `check` and `proof` yourself and state them in the setup PR. If nobody can answer the question,
because this is CI or a headless run, use your candidates and say so in the PR.

## 3. Repo settings

`scripts/setup-repo.sh settings <paths|none>`

This sets squash-only merges with the PR title and body, auto-merge, and branch deletion on merge. It
also creates the labels and sets the `AGENT_GIT_WORKFLOW_OWNER` and `AGENT_GIT_WORKFLOW_CORE` variables.

## 4. Setup PR

On branch `agent-git-workflow/setup`, add:

- `.github/workflows/agent-gate.yml`, copied from [assets/agent-gate.yml](../assets/agent-gate.yml).
- With core paths only: `.github/CODEOWNERS`, starting with `# Root paths (agent-git-workflow). Change only through a root PR.`
  Then `/.github/` and `/docs/decisions/`, then the chosen paths. Each entry gets a `#` reason line,
  then `<pattern> @<owner>`.
- The section from [assets/agents-section.md](../assets/agents-section.md), filled in and added to
  `AGENTS.md`. Create the file if it's missing. If `CLAUDE.md` exists, make sure it imports or points to
  `AGENTS.md`.
- `docs/decisions/<date>-adopt-agent-git-workflow.md`, a decision record of the chosen root paths, check
  and proof.
- If you added a `check` command, add it as well.
- In workflows that run on `push` to any branch, add `branches-ignore: [agent-evidence]`.

The owner's answer in step 2 counts as approval of this PR, so merge it without the label. The ruleset
isn't on yet.

## 5. Ruleset

`scripts/setup-repo.sh ruleset <CI check names...>`

This protects the default branch from direct pushes, force pushes and deletion, and requires
`agent-gate` plus the named checks, run by GitHub Actions. There is no bypass, because agents act as the
owner. In an emergency the owner disables the ruleset in the repo settings. Rulesets on private repos need
a paid plan. On the Free plan, tell the owner that only agents following step 7 of the skill hold root
PRs back.

## 6. Prove the gate works

With nothing core, skip to the last paragraph: there is nothing to prove until the owner asks for an
approval.

1. Pick a small real root change if one is waiting. Otherwise open a probe PR that adds a comment under
   `.github/`, with no decision record. Expect `agent-gate` to fail asking for a record.
2. Add the decision record. Expect `agent-gate` to say it's waiting for the `owner-approved` label.
3. Ask the owner to add the label. Expect `agent-gate` to pass.
   - If it stays red, rerun its latest run with `gh run rerun <id>`, and add that step to AGENTS.md as a
     trap.
4. Merge a real change. Close a probe without merging and delete its branch.

Tell the owner where root PRs waiting for them show up:
`https://github.com/<owner>/<repo>/pulls?q=is:open+label:tier:root+-label:owner-approved`. GitHub doesn't
notify you about your own account's actions, so a bookmark is the simplest inbox.
