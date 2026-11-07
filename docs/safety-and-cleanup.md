# Safety and cleanup

What `wt` will and will not do to your repositories and files.

- [Safety behavior](#safety-behavior)
- [Cleanup behavior](#cleanup-behavior)
- [Security notes](#security-notes)

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
