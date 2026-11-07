# Troubleshooting

Common errors and what to do about them.

- [“not inside a wt workspace”](#not-inside-a-wt-workspace)
- [“invalid feature name”](#invalid-feature-name)
- [“exists but is not a valid ... worktree”](#exists-but-is-not-a-valid--worktree)
- [“unsafe .wt-include path”](#unsafe-wt-include-path)
- [“wt-include source not found”](#wt-include-source-not-found)
- [Cleanup refuses because of uncommitted changes](#cleanup-refuses-because-of-uncommitted-changes)
- [`wt list` says there are no lanes](#wt-list-says-there-are-no-lanes)
- [Cleanup says the lane is not empty](#cleanup-says-the-lane-is-not-empty)
- [`code` is not suggested after creation](#code-is-not-suggested-after-creation)
- [Realpath or checksum tooling differs across systems](#realpath-or-checksum-tooling-differs-across-systems)

## “not inside a wt workspace”

Run the command from a directory that contains `.wt-workspace`, or search upward from a lane inside that workspace.

Create a marker with:

```bash
touch .wt-workspace
```

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

## “unsafe .wt-include path”

Remove the offending line from the main repository’s `.wt-include`. Absolute paths, traversal paths, comment lines, and paths containing a `.git` component are rejected.

## “wt-include source not found”

The named file is not present in the main checkout. Correct or remove the path. `wt` fails rather than silently skipping stale entries.

## Cleanup refuses because of uncommitted changes

Review `git status` in each listed lane repository. Cleanup performs this check before removing any worktree, so the lane remains unchanged until the repositories are clean.

## `wt list` says there are no lanes

Current listing requires `.wt-lane`. Lanes created by older versions may need their metadata regenerated. If the repositories are valid worktrees, rerun:

```bash
wt create <feature>
```

## Cleanup says the lane is not empty

The lane contains files not recognized as generated. Review its contents. If the extra content is intended to be retained, leaving it in place is expected.

## `code` is not suggested after creation

`wt` prints the VS Code launch hint only when the `code` command is available. You can still open the `.code-workspace` file directly.

## Realpath or checksum tooling differs across systems

Lane color uses `md5sum`, then `md5`, then `cksum`. Path canonicalization is skipped when `realpath -m` is unavailable. Basic worktree operations remain functional.
