# Troubleshooting

Common errors and what to do about them.

- [“not inside a wt workspace”](#not-inside-a-wt-workspace)
- [“uses the old layout”](#uses-the-old-layout)
- [“invalid feature name”](#invalid-feature-name)
- [“exists but is not a valid ... worktree”](#exists-but-is-not-a-valid--worktree)
- [“contains lane” / “is inside lane”](#contains-lane--is-inside-lane)
- [“is not a lane (no .wt-lane)”](#is-not-a-lane-no-wt-lane)
- [“could not fetch origin”](#could-not-fetch-origin)
- [“not found in ...; branching from its current HEAD”](#not-found-in--branching-from-its-current-head)
- [“no .wt/lane_root/ or .wt/repos/”](#no-wtlane_root-or-wtrepos)
- [“cleanup would delete work that exists nowhere else”](#cleanup-would-delete-work-that-exists-nowhere-else)
- [Cleanup keeps lane files](#cleanup-keeps-lane-files)
- [`wt list` says there are no lanes](#wt-list-says-there-are-no-lanes)
- [`code` is not suggested after creation](#code-is-not-suggested-after-creation)
- [Realpath or checksum tooling differs across systems](#realpath-or-checksum-tooling-differs-across-systems)

## “not inside a wt workspace”

Run the command from a directory that contains `.wt/workspace.sh`, or search upward from a lane inside that workspace.

Create a marker with:

```bash
mkdir -p .wt && touch .wt/workspace.sh
```

## “uses the old layout”

The workspace still has `.wt-workspace` and `.wt-templates/` from an older
version. `wt` prints the commands to move them into `.wt/`; they are also in
[Configuration](configuration.md#layout). Run them from the workspace root, then
rerun your command. Existing lanes are not affected.

## “invalid feature name”

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

## “exists but is not a valid ... worktree”

The lane path is occupied by a regular directory, file, stale directory, or unrelated clone. Inspect the path manually and move or remove it.

## “contains lane” / “is inside lane”

A lane's name is its branch name, and Git cannot have both `foo` and
`foo/bar` as branches. `wt create foo` is refused while lane `foo/bar` exists,
and `wt create foo/bar` while lane `foo` exists. Pick a name that is not a
prefix of, or prefixed by, an existing lane.

## “is not a lane (no .wt-lane)”

`wt cleanup` only works on a directory with a `.wt-lane` marker. Check the name
with `wt list` — you may have given a parent directory such as `feat` instead of
the lane `feat/gift-card-checkout`. A lane created by a version that predates
the marker can get one with `wt create <feature> <repos already in it>`.

## “could not fetch origin”

The repository has no `origin` remote, or it could not be reached. The lane
was still created, but its base may be behind the remote. Fetch manually and
rebase the lane branch if that matters.

## “not found in ...; branching from its current HEAD”

The base (`DEFAULT_BASE`, or the repository’s `origin/HEAD`, or `origin/main`)
does not exist in that repository, so the branch starts from whatever the main
checkout has checked out. Check the branch with `git -C <lane>/<repo> log -1`;
set `DEFAULT_BASE` in `.wt/workspace.sh` if your default branch has another name.

## “no .wt/lane_root/ or .wt/repos/”

Informational: the workspace has no templates, so the lane has only its
worktrees and generated files. See [Templates](templates.md#templates).

## “cleanup would delete work that exists nowhere else”

```text
warning: cleanup would delete work that exists nowhere else:
  checkout-api/main.go (uncommitted)
  HANDOVER.md (edited template copy)
Delete it anyway? [y/N]
```

Nothing has been removed yet. Commit or copy out what you want to keep, then
rerun cleanup — or answer `y` to delete it. If cleanup instead says
`cannot confirm without a terminal`, it was run from a script or an agent;
run it yourself in a terminal.

## Cleanup keeps lane files

```text
note: worktrees removed; kept lane files that wt did not create:
  .tmp
  when done with them: rm -rf "…/.worktrees/gift-card-checkout"
```

The worktrees, merged branches and everything `wt` placed are already gone. The
listed entries were created by you or an agent, so `wt` leaves them to you. Keep
what you need, then run the printed `rm -rf` line.

## `wt list` says there are no lanes

Listing requires `.wt-lane` in the lane root. Lanes created by older versions
may lack it. If the repositories are valid worktrees, rerun create with **the
repositories already in the lane** — without them, `create` adds every
repository in the workspace:

```bash
wt create <feature> <repo> [repo...]
```

## `code` is not suggested after creation

`wt` prints the VS Code launch hint only when the `code` command is available. You can still open the `.code-workspace` file directly.

## Realpath or checksum tooling differs across systems

Lane color uses `md5sum`, then `md5`, then `cksum`. Path canonicalization is skipped when `realpath -m` is unavailable. Basic worktree operations remain functional.
