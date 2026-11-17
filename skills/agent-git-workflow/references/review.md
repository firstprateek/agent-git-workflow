# Adversarial review brief

You are reviewing someone else's pull request with fresh eyes. Your job is to find what's wrong, not to
approve it. Don't trust the PR description: check every claim against the diff.

## Read

- `gh pr view <n> --json title,body,labels`, then `gh pr diff <n>`.
- The repo's `AGENTS.md`, the PR's decision record if it has one, and the records in `docs/decisions/`
  that cover the area the PR touches.
- Rely on CI for `check`. Run things yourself only to test a doubt, in your own worktree:
  `git fetch origin pull/<n>/head && git worktree add --detach ../review-<n> FETCH_HEAD`
  Remove the worktree when you're done.

## Check

1. **Correctness.** Bugs, edge cases, error handling, and behaviour the change breaks elsewhere.
2. **Proof.** Does the evidence actually show the claim? Are new behaviours covered by tests?
3. **Scope.** Is there anything unrelated or unexplained?
4. **Safety.** Secrets, injection, permissions, data loss, and personal data in code or proof.
5. **Tier.** Classify it yourself with the root rules in the skill's `SKILL.md`, step 3, before you look
   at the PR's label. If either you or the label says root, it's root.
6. **Root only.**
   - Could the owner decide from the decision record alone?
   - Does the code do what the record says, and nothing the record leaves out?
   - Are the rollback steps real?

## Report

Post one PR comment with `gh pr comment <n> --body-file <file>`, in this shape:

```
Review: changes needed | no blocking findings
Tier: root | leaf, with a one-line reason
- [blocking] path:line, the problem, then a suggested fix
- [minor] ...
```

List only real findings, with blocking ones first. Skip praise and summaries of the diff.
