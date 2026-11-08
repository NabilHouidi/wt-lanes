# Configuration

`wt` is configured through `.wt/workspace.sh`, a plain shell file in the workspace
root that `wt` sources on every run. Because it is sourced, it can execute
arbitrary commands — only use it in workspaces you control (see
[Security notes](safety-and-cleanup.md#security-notes)).

- [Layout](#layout)
- [Repository list](#repository-list)
- [Default base branch](#default-base-branch)
- [Repository discovery rules](#repository-discovery-rules)

The lane guide (`AGENTS.md`, `CLAUDE.md`) is not configured here: it is an
ordinary lane template, see [Lane guide](templates.md#lane-guide).

## Layout

Everything `wt` reads from a workspace lives in `.wt/`:

```text
.wt/
├── workspace.sh      # marks the workspace root; sourced, may be empty
├── lane_root/        # copied into the root of every lane
├── repos/<repo>/     # copied into every worktree of <repo>
└── README.md         # optional notes; ignored by wt
```

Sharing a setup between workspaces is copying this one directory.

### Migrating from `.wt-workspace` and `.wt-templates/`

Older versions used `.wt-workspace` and `.wt-templates/{_lane,<repo>}`. When
`wt` finds `.wt-workspace`, it stops and prints these commands; run them from
the workspace root:

```bash
mkdir -p .wt/repos && mv .wt-workspace .wt/workspace.sh
if [ -d .wt-templates ]; then
  if [ -d .wt-templates/_lane ]; then mv .wt-templates/_lane .wt/lane_root; fi
  for d in .wt-templates/*/; do if [ -d "$d" ]; then mv "$d" .wt/repos/; fi; done
  if [ -f .wt-templates/README.md ]; then mv .wt-templates/README.md .wt/; fi
  rmdir .wt-templates
fi
```

Existing lanes need no change.

## Repository list

```bash
REPOS=(checkout-api checkout-web shared-events)
```

When `REPOS` is unset, `wt` discovers Git repositories that are direct children of the workspace root.

Repository names are expected to be simple directory names. Slashes, `..`, `.`, and names beginning with `-` are rejected.

## Default base branch

```bash
DEFAULT_BASE=origin/main
```

If unset, `wt` uses each repository’s `origin/HEAD`, and `origin/main` when `origin/HEAD` is not set.

Before branching, `wt` fetches `origin` in each repository. It warns instead of failing when:

- the fetch fails (no `origin`, offline) — the base may be stale;
- the base does not exist — the lane branches from the main checkout’s current `HEAD`.

An existing local branch with the feature name is attached as-is, whatever the base.

Example with a repository list and default base:

```bash
REPOS=(checkout-api checkout-web)
DEFAULT_BASE=origin/main
```

## Repository discovery rules

A directory is eligible as a repository when:

- It is a direct child of the directory containing `.wt/workspace.sh`.
- Its name is a simple directory name.
- It is a repository root, not merely a subdirectory of another repository.

The original repository checkout remains the owner of lane worktrees. `wt` adds linked worktrees; it does not move the main checkout.
