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
- [Configuration](#configuration)
- [Repository discovery rules](#repository-discovery-rules)
- [Templates](#templates)
- [Live ignored configuration](#live-ignored-configuration)
- [Generated lane files](#generated-lane-files)
- [IDE behavior](#ide-behavior)
- [Safety behavior](#safety-behavior)
- [Cleanup behavior](#cleanup-behavior)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Guides and examples](#guides-and-examples)
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

## Configuration

`.wt-workspace` is plain shell configuration sourced by `wt`.

### Repository list

```bash
REPOS=(checkout-api checkout-web shared-events)
```

When `REPOS` is unset, `wt` discovers Git repositories that are direct children of the workspace root.

Repository names are expected to be simple directory names. Slashes, `..`, `.`, and names beginning with `-` are rejected.

### Default base branch

```bash
DEFAULT_BASE=origin/main
```

If unset, `wt` attempts to infer the default branch from each repository’s `origin/HEAD`.

Example with a repository list and default base:

```bash
REPOS=(checkout-api checkout-web)
DEFAULT_BASE=origin/main
```

### Lane guide

`wt` creates a generic `AGENTS.md` by default. Rename it through workspace configuration if your agent expects a different file:

```bash
LANE_GUIDE=CLAUDE.md
```

Disable generation entirely with:

```bash
LANE_GUIDE=
```

The value must be a simple filename without path components.

## Repository discovery rules

A directory is eligible as a repository when:

- It is a direct child of the directory containing `.wt-workspace`.
- Its name is a simple directory name.
- It is a repository root, not merely a subdirectory of another repository.

The original repository checkout remains the owner of lane worktrees. `wt` adds linked worktrees; it does not move the main checkout.

## Templates

Templates are optional.

```text
.wt-templates/
├── _lane/
├── checkout-api/
└── checkout-web/
```

### Lane templates

```text
.wt-templates/_lane/
```

Contents are copied to the root of each feature lane.

Examples:

```text
.wt-templates/_lane/
├── HANDOVER.md
├── DESIGN.md
├── .envrc
├── .idea/
├── .run/
└── .vscode/
```

Top-level files whose names end in `.tmpl` are not copied.

Existing files are not overwritten unless `--force` is supplied. Existing directories are merged without replacing existing files.

Do not name a lane template directory after a repository (for example, `.wt-templates/_lane/checkout-api`). Because repositories are also lane subdirectories, such a template can be merged into the repository worktree.

### Repository templates

```text
.wt-templates/checkout-api/
```

Contents are copied into the newly created `checkout-api` worktree for a lane.

Examples:

```text
.wt-templates/checkout-api/
├── .vscode/
├── .run/
├── .envrc
└── config/
    └── local.yaml
```

When a worktree is newly created, `wt` copies repository templates and live includes with their normal overwrite behavior. When a valid worktree already exists, rerunning `wt create` repairs it: template files and live includes are copied only when missing. Use `--force` to refresh or overwrite those entries.

## Live ignored configuration

A main repository may contain `.wt-include`:

```text
checkout-api/.wt-include
```

List relative files, one per line:

```text
.envrc
config/local.yaml
.dev/local-settings.json
```

These files are copied from the main checkout into the corresponding lane worktree after repository templates are applied.

Rules:

- Blank lines are ignored.
- Absolute paths cause the command to fail.
- Paths containing `.` or `..` components cause the command to fail.
- Any path containing a `.git` component is unsafe and causes the command to fail.
- A missing source file causes the command to fail.
- Destination directories are created automatically.
- Comments are not supported; a comment line will be treated as an invalid path.
- On a newly created worktree, live includes overwrite template files.
- On a repaired existing worktree, live includes are copied only when missing unless `--force` is used.

Use this for local, Git-ignored settings—not for committing credentials.

## Generated lane files

### `.wt-lane`

Contains the feature name. It identifies the directory as a lane and helps `wt list` find lanes regardless of nesting depth.

### `.wt-lane-manifest`

Lists top-level lane entries generated by `wt`. Cleanup uses it to distinguish tool-owned scaffolding from user-authored files.

### `AGENTS.md`

The default generated lane guide for AI coding agents. It contains:

- the feature name
- repositories present in the lane
- generic editing and testing rules

The guide’s filename can be configured through `.wt-workspace`:

```bash
LANE_GUIDE=CLAUDE.md
```

Set it to an empty value to disable generated lane-guide creation:

```bash
LANE_GUIDE=
```

Provide a lane template file such as `.wt-templates/_lane/AGENTS.md` if your workspace needs project-specific instructions. Without `--force`, an existing generated guide is preserved.

### `<feature-name>.code-workspace`

A VS Code workspace containing one folder: the lane root.

Repository subfolders and lane documentation are reachable from that root. Each lane receives a deterministic title and status-bar color based on the feature name.

Without `--force`, an existing workspace file is preserved, so local customizations are not overwritten.

## IDE behavior

### VS Code

Open the generated workspace from the lane directory:

```bash
code gift-card-checkout.code-workspace
```

For a nested feature:

```bash
code "$(wt path team/gift-card-checkout)/gift-card-checkout.code-workspace"
```

Shared VS Code settings come from templates: `.wt-templates/_lane/.vscode/` lands in the lane root, `.wt-templates/<repo>/.vscode/` in each repository worktree. Personal, Git-ignored settings (for example your own `.vscode/settings.json`) can be carried into every lane through `.wt-include`; live includes win over template copies.

### JetBrains

JetBrains support is provided through templates. If present, `.wt-templates/_lane/.idea` is copied or merged into the lane root. Per-repository `.idea` or `.run` content can be supplied the same way through `.wt-templates/<repo>/`.

If the resulting lane has `.idea` but no `.idea/.name`, `wt` creates `.name` using the workspace root’s directory name. Existing IDE files are not replaced without `--force`.

## Safety behavior

`wt`:

- validates feature names as Git branch names
- rejects path-traversal components
- canonicalizes lane paths where supported
- refuses lane names resolving outside `.worktrees`
- restricts repository names to simple directory names
- requires repository paths to be actual repository roots
- rejects unsafe `.git`, absolute, missing, and traversal `.wt-include` paths loudly
- only treats an existing target as a lane when it is a matching linked worktree
- prechecks main-repository linkage and uncommitted changes before removing anything
- uses normal `git worktree remove`, preserving its dirty-worktree protection
- uses `git branch -d`, refusing to force-delete unmerged branches
- avoids overwriting generated files without `--force`
- avoids deleting unrecognized lane files during cleanup
- preserves template-copied lane files once you edit them

No `git clean`, `git reset`, `git rebase`, `git commit`, `git push`, or branch-force deletion is performed.

## Cleanup behavior

`wt cleanup` discovers worktrees directly inside the lane instead of depending on the current global `REPOS` setting.

Before removing anything, it checks that:

1. each discovered target is a valid repository root,
2. its main repository exists,
3. the target is actually linked to that main repository,
4. no discovered worktree has staged, modified, or nonignored untracked changes.

If any repository fails these checks, cleanup stops and no worktree is removed.

For each repository it then:

1. removes the linked worktree,
2. prunes stale worktree metadata,
3. attempts safe feature-branch deletion.

After repository cleanup:

- If all remaining lane entries are known to be generated, they are removed.
- If the lane contains unrecognized files, lane files are left in place.
- With `--force`, recognized generated entries are removed, but unrecognized files are still preserved.

A file copied from a `_lane` template counts as generated only while it is
byte-identical to the template. Once you edit it — a filled-in `HANDOVER.md`,
for example — it is treated as your file and is preserved, even with `--force`.

This allows durable lane notes such as `HANDOVER.md` to remain while the rest of the lane is cleaned.

## Security notes

### `.wt-workspace` executes shell code

The workspace marker is sourced, so it can execute arbitrary commands. Use it only inside workspaces you control.

Avoid placing the tool in directories containing untrusted projects that may supply a `.wt-workspace`.

### `.wt-include` may copy sensitive files

The files copied into lanes are usually Git-ignored local configuration and may contain credentials.

Protect your workspace directories appropriately, do not commit lane content, and avoid listing broad or sensitive paths.

## Troubleshooting

### “not inside a wt workspace”

Run the command from a directory that contains `.wt-workspace`, or search upward from a lane inside that workspace.

Create a marker with:

```bash
touch .wt-workspace
```

### “invalid feature name”

Use a valid Git branch name. Do not use:

- empty names
- leading slashes
- leading dashes
- `.` or `..` path components
- double slashes
- invalid Git branch characters

Examples that normally work:

```text
gift-card-checkout
team/gift-card-checkout
feature/2026-11-payment-rules
```

### “exists but is not a valid ... worktree”

The lane path is occupied by a regular directory, file, stale directory, or unrelated clone. Inspect the path manually and move or remove it.

### “unsafe .wt-include path”

Remove the offending line from the main repository’s `.wt-include`. Absolute paths, traversal paths, comment lines, and paths containing a `.git` component are rejected.

### “wt-include source not found”

The named file is not present in the main checkout. Correct or remove the path. `wt` fails rather than silently skipping stale entries.

### Cleanup refuses because of uncommitted changes

Review `git status` in each listed lane repository. Cleanup performs this check before removing any worktree, so the lane remains unchanged until the repositories are clean.

### `wt list` says there are no lanes

Current listing requires `.wt-lane`. Lanes created by older versions may need their metadata regenerated. If the repositories are valid worktrees, rerun:

```bash
wt create <feature>
```

### Cleanup says the lane is not empty

The lane contains files not recognized as generated. Review its contents. If the extra content is intended to be retained, leaving it in place is expected.

### `code` is not suggested after creation

`wt` prints the VS Code launch hint only when the `code` command is available. You can still open the `.code-workspace` file directly.

### Realpath or checksum tooling differs across systems

Lane color uses `md5sum`, then `md5`, then `cksum`. Path canonicalization is skipped when `realpath -m` is unavailable. Basic worktree operations remain functional.

## Guides and examples

- [Workflows and recipes](docs/workflows.md) — everyday patterns: feature lanes, PR review, hotfixes, AI agent lanes, and adoption tips.
- [`examples/`](examples/) — a copyable example workspace configuration, templates, and a demo script that builds a scratch workspace so you can try `wt` safely.

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
