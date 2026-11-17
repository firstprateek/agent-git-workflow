## Agent git workflow

Agents land every change through a pull request, following [agent-git-workflow](https://github.com/firstprateek/agent-git-workflow).

- check: `<command>`. It must pass before a PR is opened.
- proof: <what a PR must show, e.g. "screenshots of changed screens at 390 and 1280 px wide">
- core: <paths | none>. With `none`, nothing needs the owner's approval unless they ask for it on a change.
- owner: @<owner login>. Agents act on GitHub as the owner.
- <core paths only:> Root paths are in `.github/CODEOWNERS`, each with its reason.
- Decision records are in `docs/decisions/`.
- Leaf PRs auto-merge after a fresh-context review and green checks. Root PRs (with `core: none`, only
  changes the owner asked to approve) also need a decision record, and the owner approves it by adding
  the `owner-approved` label. Agents never add or remove that label, and never push to the default
  branch.
- Waiting for the owner: `is:open is:pr label:tier:root -label:owner-approved`.
