# Workflows and recipes

Practical patterns for using `wt` day to day. Each recipe assumes you are inside
a workspace (a directory containing `.wt-workspace`).

- [Develop a cross-repository feature](#develop-a-cross-repository-feature)
- [Name lanes like branches](#name-lanes-like-branches)
- [Review a pull request in isolation](#review-a-pull-request-in-isolation)
- [Hotfix against a release branch](#hotfix-against-a-release-branch)
- [Run AI coding agents in parallel lanes](#run-ai-coding-agents-in-parallel-lanes)
- [Carry local configuration into every lane](#carry-local-configuration-into-every-lane)
- [Adopt `wt` gradually in an existing workspace](#adopt-wt-gradually-in-an-existing-workspace)

## Develop a cross-repository feature

The everyday loop: one lane per feature, one branch name everywhere.

```bash
wt create gift-card-checkout
code "$(wt path gift-card-checkout)/gift-card-checkout.code-workspace"
```

Work inside each repository as usual — `wt` never stages, commits, or pushes for
you. Check on all your lanes from anywhere in the workspace:

```bash
wt list
```

After the PRs are merged, remove the lane. Cleanup refuses to touch worktrees
with uncommitted changes, so commit or discard your work first:

```bash
wt cleanup gift-card-checkout
```

If you kept notes in the lane root (for example `HANDOVER.md`), cleanup reports
them as non-generated and leaves the lane files in place. Remove them yourself
when you no longer need them.

## Name lanes like branches

A lane name doubles as the Git branch created in every repository, so the
branch naming conventions you already use work — including hierarchy:

```bash
wt create feat/gift-card-checkout
wt create hotfix/1.2.4-double-charge checkout-api
wt create review/pr-1234 checkout-web shared-events
```

`.worktrees/` mirrors the hierarchy, so related lanes group together and each
lane can cover a different subset of repositories:

```text
.worktrees/
├── feat/
│   └── gift-card-checkout/       # worktrees for every repo + lane files
├── hotfix/
│   └── 1.2.4-double-charge/      # checkout-api only
└── review/
    └── pr-1234/                  # checkout-web + shared-events
```

Useful prefixes: `feat/`, `fix/`, `hotfix/<version>-<what>`, `review/pr-<n>`,
`agent/<task>`, `<team>/<initiative>`.

Details worth knowing:

- The generated VS Code workspace file uses the last component:
  `.worktrees/feat/gift-card-checkout/gift-card-checkout.code-workspace`.
- `wt list` prints the full lane name, for example `feat/gift-card-checkout`.
- `wt cleanup` removes now-empty parent directories, so `.worktrees/feat/`
  disappears together with its last lane.

## Review a pull request in isolation

`wt create` attaches any *existing* local branch instead of creating a new one.
Fetch the PR branch in the affected repositories, then build a lane around it:

```bash
git -C checkout-api fetch origin pull/1234/head:pr-1234
git -C checkout-web fetch origin pull/1235/head:pr-1234

wt create pr-1234 checkout-api checkout-web
code "$(wt path pr-1234)/pr-1234.code-workspace"
```

You get a full checkout to click around in, your own branch stays untouched, and
removing the lane afterwards does not delete the local branches if they are
unmerged:

```bash
wt cleanup pr-1234
```

## Hotfix against a release branch

By default a new lane branches from `DEFAULT_BASE` (or the repository’s
`origin/HEAD`). For a hotfix that must start from a release branch, create the
branch yourself first — `wt` will attach it:

```bash
git -C checkout-api branch hotfix-1.2.4 origin/release-1.2
git -C checkout-web branch hotfix-1.2.4 origin/release-1.2

wt create hotfix-1.2.4 checkout-api checkout-web
```

Alternatively, pin the base for the whole workspace while you do release work:

```bash
# .wt-workspace
DEFAULT_BASE=origin/release-1.2
```

## Run AI coding agents in parallel lanes

Lanes are designed to be handed to an agent:

- Each lane gets a generated guide (`AGENTS.md` by default, configurable with
  `LANE_GUIDE`) naming the feature and the repositories in scope.
- The `.wt-lane` marker lets agent tooling find the lane root by walking up, so
  durable scratch work belongs in the lane instead of `/tmp`.
- Parallel agents never share a checkout, so two agents cannot switch branches
  out from under each other.

```bash
wt create agent/null-check-hardening checkout-api
# point your agent at: $(wt path agent/null-check-hardening)
```

When the agent finishes, review the worktrees with `wt list`, merge what you
want, and clean up. Files the agent wrote in the lane root (notes, findings)
survive cleanup because they are not generated content.

## Carry local configuration into every lane

Worktrees do not inherit Git-ignored files, so things like `.envrc` or local
settings go missing in a fresh lane. List them in the main checkout’s
`.wt-include` and every lane gets a copy:

```text
# checkout-api/.wt-include
.envrc
config/local.yaml
```

Details and rules are in the README under
[Live ignored configuration](../README.md#live-ignored-configuration). Keep it
to local developer settings — never commit credentials to satisfy this file.

## Adopt `wt` gradually in an existing workspace

You do not have to convert the whole team at once:

1. `touch .wt-workspace` in your meta-project directory.
2. Optionally pin the repo list while you get comfortable:
   `REPOS=(checkout-api)` in `.wt-workspace`.
3. Create your first lane for a single repository:
   `wt create trial-lane checkout-api`.
4. Add templates (`.wt-templates/`) and `.wt-include` files later, once the
   basic loop feels right. Rerunning `wt create <feature>` on an existing lane
   repairs missing scaffolding without overwriting your files.
