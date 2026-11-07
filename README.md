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
- [Global options](#global-options)
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
- Optional per-repository and lane-level IDE templates.
- Optional copying of Git-ignored local configuration.
- Generated VS Code workspaces with deterministic lane colors.
- A generated lane guide for AI coding agents or human handoff.
- Lane-aware cleanup that preserves content it did not generate.
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

`wt` walks upward from the current directory until it finds a `.wt-workspace` marker.

Create one in your meta-project directory:

```bash
touch .wt-workspace
```

The marker file may be empty.

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
touch .wt-workspace
wt create gift-card-checkout
```

Expected output:

```text
==> checkout-api
==> checkout-web
==> shared-events

ready: /home/you/commerce-workspace/.worktrees/gift-card-checkout
  workspace: /home/you/commerce-workspace/.worktrees/gift-card-checkout/gift-card-checkout.code-workspace
  code "/home/you/commerce-workspace/.worktrees/gift-card-checkout/gift-card-checkout.code-workspace"
```

The original checkouts remain untouched:

```text
commerce-workspace/
├── .worktrees/
│   └── gift-card-checkout/
│       ├── AGENTS.md
│       ├── .wt-lane
│       ├── .wt-lane-manifest
│       ├── checkout-api/
│       ├── checkout-web/
│       ├── gift-card-checkout.code-workspace
│       └── shared-events/
├── .wt-workspace
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

Commit, push, and create PRs normally inside each repository lane. `wt` does not create commits for you.

When the work is merged, remove the lane. `wt` first checks every lane worktree; if one has staged, modified, or nonignored untracked files, cleanup stops before removing anything. Once the repositories are clean:

```bash
wt cleanup gift-card-checkout
```

Example output:

```text
==> checkout-api
==> checkout-web
    branch gift-card-checkout kept (unmerged or absent)
==> shared-events
```

If you leave notes such as `gift-card-checkout/HANDOVER.md` in the lane root, cleanup also reports that they are not generated and leaves them in place:

```text
note: lane contains non-generated files; leaving lane files in place
```

## Workspace layout

The recommended layout is:

```text
commerce-workspace/
├── .wt-workspace
├── wt
├── checkout-api/
├── checkout-web/
├── shared-events/
├── .worktrees/
└── .wt-templates/
    ├── _lane/
    ├── checkout-api/
    └── checkout-web/
```

Only the marker, main repositories, and optional template directories are required. `.worktrees/` is created automatically.

## Commands

Global options must appear before the command:

```bash
wt [global-options] <command> [arguments]
```

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

Rerunning `create` on an existing lane repairs missing repository and lane scaffolding. Files already present in the lane are preserved unless `--force` is used.

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

Remove lane worktrees and attempt safe branch cleanup:

```bash
wt cleanup <feature>
```

### `wt help`

```bash
wt help
```

## Global options

### `--force`

```bash
wt --force create <feature>
wt --force cleanup <feature>
```

For `create`, allow lane templates and generated files to overwrite existing entries.

For `cleanup`, remove recognized generated lane entries even when the lane also contains unrecognized files. Unrecognized files are still not deleted.

The flag must precede the subcommand.

You can also use:

```bash
WT_FORCE=1 wt create gift-card-checkout
```

## Safety

`wt` is designed to never destroy your work:

- Feature names are validated as Git branch names; lane paths resolving outside `.worktrees` are refused.
- Existing files are never overwritten without `--force`.
- Cleanup checks every lane worktree for uncommitted changes *before* removing anything, and deletes branches with `git branch -d` — never a force delete.
- Lane files `wt` did not generate are preserved, including template files you have since edited.

It never runs `git clean`, `git reset`, `git rebase`, `git commit`, or `git push`. See [Safety and cleanup](docs/safety-and-cleanup.md) for the full list.

## Documentation

- [Workflows and recipes](docs/workflows.md) — everyday patterns: lane naming, feature lanes, PR review, hotfixes, AI agent lanes, and adoption tips.
- [Configuration](docs/configuration.md) — `.wt-workspace` settings: `REPOS`, `DEFAULT_BASE`, `LANE_GUIDE`, and repository discovery rules.
- [Customizing lanes](docs/templates.md) — templates, `.wt-include` live configuration, generated lane files, and IDE setup.
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

The implementation is intentionally kept as a single Bash script for simple installation.

## License

MIT
