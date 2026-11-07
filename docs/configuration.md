# Configuration

`wt` is configured through `.wt-workspace`, a plain shell file in the workspace
root that `wt` sources on every run. Because it is sourced, it can execute
arbitrary commands — only use it in workspaces you control (see
[Security notes](safety-and-cleanup.md#security-notes)).

- [Repository list](#repository-list)
- [Default base branch](#default-base-branch)
- [Lane guide](#lane-guide)
- [Repository discovery rules](#repository-discovery-rules)

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

If unset, `wt` attempts to infer the default branch from each repository’s `origin/HEAD`.

Example with a repository list and default base:

```bash
REPOS=(checkout-api checkout-web)
DEFAULT_BASE=origin/main
```

## Lane guide

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
