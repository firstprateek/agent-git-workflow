# Learning what's critical

CODEOWNERS is the repo's map of root paths. Keep it matched to where the owner's review actually changes
outcomes. Use evidence and propose changes. Never edit it quietly.

## Gather evidence

Start from the last learning PR:

```
since=$(gh pr list --state merged --search "CODEOWNERS in:title" --limit 1 --json mergedAt --jq '.[0].mergedAt // "1970-01-01"' | cut -c1-10)
gh pr list --state merged --label tier:root --search "merged:>$since" --limit 100 \
  --json number,files,reviews --jq '.[] | {n: .number, files: [.files[].path], owner_reviews: [.reviews[].state]}'
gh pr list --state merged --search "merged:>$since Regressed-by in:body" --limit 100 --json number,body \
  --jq '.[] | {fix: .number, regressed_by: (.body | [scan("Regressed-by: #([0-9]+)")[0]])}'
```

For each regressing PR, list its files and tier:
`gh pr view <n> --json files,labels --jq '{files: [.files[].path], labels: [.labels[].name]}'`

## Decide

- **Add a root path** when:
  - a leaf PR caused a regression; or
  - on a root PR, the owner requested changes or the decision record changed after their first review,
    and the PR's area has no root path yet.

  Add the narrowest pattern that covers the files involved.
- **Narrow or remove a root path** when its last 5 or more root PRs were all approved without changes,
  and no regression points into it. Propose it. The owner decides.
- **Keep** a path that has no root PRs yet. A lack of evidence is not a reason to remove it.

## Propose

Open one PR labelled `tier:root`, titled `CODEOWNERS: <summary>`, with a decision record that lists each
change, its evidence (PR numbers) and the reason. Have at most one learning PR open at a time.
