# agent-git-workflow

An [Agent Skill](https://agentskills.io) that lets coding agents land changes on GitHub on their own.
You review only the changes that matter, and you review a one-page decision record rather than the code.

- **Every change** goes through a PR with proof (screenshots, transcripts, test output) and an
  adversarial review by a fresh agent.
- **Leaf changes** auto-merge when checks pass.
- **Root changes** wait for your approval. A change is root if it touches the repo's critical paths, or
  if it changes core design, interfaces, data, security, dependencies or CI.
- **Root paths** live in `CODEOWNERS`, each with a reason, and the agent proposes changes to them based
  on evidence.
- **Decision records** in `docs/decisions/` keep the reasoning behind key choices, so agents don't
  reopen them.

Agents act on GitHub as you, with your `gh` login. Setup asks you one thing: which parts of the code
are core. "Nothing" is a valid answer: then every change merges after checks and review, unless you ask
to approve a particular one. You approve a root PR by adding the `owner-approved` label, which agents are never allowed to
add. That rule is the lock, so this suits agents you already trust to follow instructions.

## Install

Claude Code:

```
/plugin install agent-git-workflow --marketplace firstprateek/agent-git-workflow
```

Other agents that support [Agent Skills](https://agentskills.io): copy `skills/agent-git-workflow/` into
their skills folder.

Then ask your agent to "set up agent-git-workflow in this repo".

## Needs

`git`, `jq` and the GitHub CLI (`gh`) signed in with the `repo` and `workflow` scopes. GitHub only.
Rulesets on private repos need a paid GitHub plan. Without them, nothing on GitHub stops a root PR from
merging; only the agents following the skill hold it back.

## License

MIT
