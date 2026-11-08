# wt-lanes

`wt-lanes` (command: `wt`) is a Bash command-line tool for managing multi-repository Git worktree lanes in a meta-project workspace.

A **lane** is a feature-scoped directory that contains linked Git worktrees from several repositories. For example, the feature `gift-card-checkout` can contain matching `checkout-api`, `checkout-web`, and `shared-events` worktrees under one directory, with shared documentation, IDE settings, and a VS Code workspace.

## Contents

- [Why use `wt`](#why-use-wt)
- [Installation](#installation)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Workspace layout](#workspace-layout)
- [Commands](#commands)
- [Safety](#safety)
- [Documentation](#documentation)
- [Development](#development)
- [License](#license)

## Why use `wt`

Use `wt` when a feature crosses repository boundaries and you want isolated parallel workspaces instead of repeatedly switching branches.

It provides:

- One directory per feature.
- Linked Git worktrees for each selected repository.
- Automatic branch naming based on the feature.
- Optional per-repository and lane-level templates: IDE settings, `.envrc`, a lane guide for AI coding agents or human handoff.
- Generated VS Code workspaces with deterministic lane colors.
- Cleanup that removes the lane's worktrees, merged branches and every file `wt` placed — after listing any uncommitted or edited work it would delete and asking first.
- Protection against paths that resolve outside the workspace.

## Installation

Make the script executable:

```bash
chmod +x wt
```

Run it from a workspace root:

```bash
./wt help
```

To install it on your `PATH`:

```bash
mkdir -p ~/.local/bin
ln -s "$PWD/wt" ~/.local/bin/wt
```

Ensure `~/.local/bin` is present in your `PATH`.

### Windows

`wt` is a Bash script. On Windows, run it through WSL, MSYS2, Git Bash, or another environment that provides Bash and Git.

## Requirements

Required:

- Bash
- Git

Optional:

- `direnv` — automatically allow generated `.envrc` files
- VS Code — open generated `.code-workspace` files
- `md5sum`, `md5`, or `cksum` — assign deterministic lane colors
- JetBrains IDEs — use optional `.idea` lane templates

### Workspace root

`wt` walks upward from the current directory until it finds a `.wt/workspace.sh` marker.

Create one in your meta-project directory:

```bash
mkdir -p .wt && touch .wt/workspace.sh
```

The file may be empty; it doubles as the workspace's configuration (see [Configuration](docs/configuration.md)).

## Quick start

Imagine three repositories sitting next to one another:

```text
commerce-workspace/
├── checkout-api/
├── checkout-web/
└── shared-events/
```

A new “gift card checkout” feature requires changes in all three. Rather than switching branches three times, create one isolated lane:

```bash
cd commerce-workspace
mkdir -p .wt && touch .wt/workspace.sh
wt create gift-card-checkout
```

Expected output (Git's own lines shortened to the first repository):

```text
==> checkout-api
Preparing worktree (new branch 'gift-card-checkout')
branch 'gift-card-checkout' set up to track 'origin/main'.
HEAD is now at ce7ff1b init
==> checkout-web
…
==> shared-events
…
note: no .wt/lane_root/ or .wt/repos/ in /home/you/commerce-workspace; lane has no scaffolding

ready: /home/you/commerce-workspace/.worktrees/gift-card-checkout
  workspace: /home/you/commerce-workspace/.worktrees/gift-card-checkout/gift-card-checkout.code-workspace
  code "/home/you/commerce-workspace/.worktrees/gift-card-checkout/gift-card-checkout.code-workspace"
```

The original checkouts remain untouched:

```text
commerce-workspace/
├── .worktrees/
│   └── gift-card-checkout/
│       ├── .wt-lane
│       ├── checkout-api/
│       ├── checkout-web/
│       ├── gift-card-checkout.code-workspace
│       └── shared-events/
├── .wt/
│   └── workspace.sh
├── checkout-api/
├── checkout-web/
└── shared-events/
```

Each repository in the lane is now on the `gift-card-checkout` branch:

```bash
cd "$(wt path gift-card-checkout)"
git -C checkout-api branch --show-current
git -C checkout-web branch --show-current
git -C shared-events branch --show-current
```

Open all repositories and lane notes as one VS Code workspace:

```bash
code gift-card-checkout.code-workspace
```

Check every lane from the main workspace:

```bash
cd /home/you/commerce-workspace
wt list
```

Example status:

```text
gift-card-checkout               checkout-api        gift-card-checkout         0 dirty  -0 +1
gift-card-checkout               checkout-web        gift-card-checkout         2 dirty  -0 +0
gift-card-checkout               shared-events       gift-card-checkout         0 dirty  ?
```

The last column is `-behind +ahead` relative to `origin/<branch>`, or `?` when that branch has not been pushed.

Commit, push, and create PRs normally inside each repository lane. `wt` does not create commits for you.

When the work is merged, remove the lane:

```bash
wt cleanup gift-card-checkout
```

Example output:

```text
==> checkout-api
Deleted branch gift-card-checkout (was ce7ff1b).
==> checkout-web
    branch gift-card-checkout kept (unmerged or absent)
==> shared-events
Deleted branch gift-card-checkout (was 38bb5a8).
```

Cleanup removes the worktrees, every branch that is merged, and everything `wt` placed in the lane root: template copies, the `.code-workspace` file, `.idea/`. If that would delete work that exists nowhere else — uncommitted changes in a worktree, or a template copy someone edited — it lists it and asks first:

```text
warning: cleanup would delete work that exists nowhere else:
  checkout-api/main.go (uncommitted)
  HANDOVER.md (edited template copy)
Delete it anyway? [y/N]
```

Without a terminal to answer (a script, an agent), it stops and removes nothing.

Files `wt` did not place, such as a `.tmp/` directory of notes, stay in the lane root and are listed:

```text
note: worktrees removed; kept lane files that wt did not create:
  .tmp
  when done with them: rm -rf "/home/you/commerce-workspace/.worktrees/gift-card-checkout"
```

## Workspace layout

The recommended layout is:

```text
commerce-workspace/
├── .wt/
│   ├── workspace.sh          # marks the workspace root; sourced shell config
│   ├── lane_root/            # copied into the root of every lane
│   ├── repos/
│   │   ├── checkout-api/     # copied into every checkout-api worktree
│   │   └── checkout-web/
│   └── README.md             # optional notes; ignored by wt
├── checkout-api/
├── checkout-web/
├── shared-events/
└── .worktrees/               # lanes, created by wt
```

Only `.wt/workspace.sh` and the main repositories are required. Workspaces that still use `.wt-workspace` and `.wt-templates/` get an error from `wt` with the commands to migrate; see [Configuration](docs/configuration.md#layout).

## Commands

### `wt create`

Create a lane for all discovered repositories:

```bash
wt create gift-card-checkout
```

Create a lane for selected repositories:

```bash
wt create gift-card-checkout checkout-api checkout-web
```

Nested feature names are allowed:

```bash
wt create team/gift-card-checkout
```

The feature name is used as the branch name in each selected repository.

New branches start from `DEFAULT_BASE` or the repository's `origin/HEAD`. If `origin` cannot be fetched, or that base does not exist, `wt` prints a warning — in the second case it branches from the main checkout's current `HEAD`.

Rerunning `create` on an existing lane restores missing repository and lane scaffolding. It never overwrites a file already in the lane; to pick up a changed template, delete the lane's copy and rerun.

`wt` does not stage, commit, push, merge, or delete commits.

### `wt list`

Show repositories in lanes that contain a `.wt-lane` marker:

```bash
wt list
```

or:

```bash
wt ls
```

The status shows the lane, repository, branch, number of dirty entries, and comparison with `origin/<branch>` when available.

### `wt path`

Print a lane directory:

```bash
wt path <feature>
```

Useful in scripts:

```bash
cd "$(wt path gift-card-checkout)/checkout-api"
```

### `wt cleanup`

Remove lane worktrees, merged branches, and the files `wt` placed in the lane:

```bash
wt cleanup <feature>
```

Uncommitted changes, edited or added files in template copies, and shelved IDE changes are listed first and need a `y` to be deleted. `.idea/` (IDE state) is deleted with the lane. Other files `wt` did not place stay and are listed, with an `rm -rf` line for the lane. A directory without a `.wt-lane` marker is refused.

### `wt help`

```bash
wt help
```

## Safety

`wt` is designed not to destroy your work:

- Feature names are validated as Git branch names; lane paths resolving outside `.worktrees` are refused.
- Files already in a lane are never overwritten.
- A lane is never created inside or around another lane, and cleanup refuses a directory without a `.wt-lane` marker.
- Before removing anything, cleanup lists uncommitted changes, edited or added files in template copies, and shelved IDE changes it would delete, and asks for confirmation; without a terminal it stops.
- Branches are deleted with `git branch -d` — never a force delete — so unmerged commits survive cleanup.
- Files in the lane root that `wt` did not place are never deleted, apart from the IDE state in `.idea/`.

One gap: Git-ignored files inside a worktree that did not come from a template (a local `.env`, build output) are deleted with the worktree without a warning. Copy out anything you need before cleanup.

It never runs `git clean`, `git reset`, `git rebase`, `git commit`, or `git push`. See [Safety and cleanup](docs/safety-and-cleanup.md) for the full list.

## Documentation

- [Workflows and recipes](docs/workflows.md) — everyday patterns: lane naming, feature lanes, PR review, hotfixes, AI agent lanes, and adoption tips.
- [Configuration](docs/configuration.md) — `.wt/workspace.sh` settings: `REPOS`, `DEFAULT_BASE`, and repository discovery rules.
- [Customizing lanes](docs/templates.md) — templates, the lane guide, generated lane files, and IDE setup.
- [Safety and cleanup](docs/safety-and-cleanup.md) — exactly what `wt` will and will not do, plus security notes.
- [Troubleshooting](docs/troubleshooting.md) — common errors and fixes.
- [`examples/`](examples/) — a copyable example workspace and a demo script that builds a scratch workspace so you can try `wt` safely.

## Development

Check syntax:

```bash
bash -n wt
```

If ShellCheck is available:

```bash
shellcheck wt
```

Run the end-to-end tests (each builds throwaway workspaces under `$TMPDIR` and removes them; exits non-zero on any failure):

```bash
tests/run.sh
```

The confirmation-prompt checks need util-linux `script` and are skipped without it (for example on macOS).

The implementation is intentionally kept as a single Bash script for simple installation.

## License

MIT
