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
- only treats an existing target as a lane when it is a matching linked worktree
- never overwrites a file already in a lane, on create or on rerun
- prechecks main-repository linkage before removing anything
- refuses to create a lane inside, or around, another lane
- refuses to clean up a directory without a `.wt-lane` marker
- lists uncommitted changes, edited or added files in template copies, and shelved IDE changes before cleanup deletes them, and asks for confirmation
- uses `git branch -d`, refusing to force-delete unmerged branches
- never deletes lane-root files it did not place, apart from the IDE state in `.idea/`

No `git clean`, `git reset`, `git rebase`, `git commit`, `git push`, or branch-force deletion is performed.

## Cleanup behavior

`wt cleanup` discovers worktrees directly inside the lane instead of depending on the current global `REPOS` setting.

Before removing anything, it checks that:

1. the directory has a `.wt-lane` marker naming this feature — so
   `wt cleanup feat` on a directory that only holds lanes `feat/a` and `feat/b`
   is refused,
1. each discovered target is a valid repository root,
2. its main repository exists,
3. the target is actually linked to that main repository.

If any repository fails these checks, cleanup stops and no worktree is removed.

It then lists work that would be deleted and exists nowhere else:

| Listed as | What |
|---|---|
| `(uncommitted)` | staged, modified, or untracked files in a worktree — except untracked files that are untouched template copies |
| `(edited template copy)` | a file copied from `.wt/lane_root/` or `.wt/repos/<repo>/` that no longer matches its template, ignored or not |
| `(added to a template copy)` | a file added inside a directory copied from `.wt/lane_root/` (for example `docs/DESIGN.md` next to a templated `docs/README.md`); `.idea/` is excluded |
| `(edited)` | the `<feature-name>.code-workspace` file, changed since `wt` generated it |
| `(shelved IDE changes)` | a non-empty `.idea/shelf/`: changes shelved in a JetBrains IDE, which are code |

Files added inside a repository template directory are not listed here: Git
already reports them as `(uncommitted)`.

If the list is not empty, cleanup asks `Delete it anyway? [y/N]`. Anything but
`y` stops it with nothing removed. Without a terminal to answer — a script, an
agent — it stops as well.

For each repository it then:

1. removes the linked worktree (`git worktree remove --force`, since the check above already covered its changes),
2. prunes stale worktree metadata,
3. attempts safe feature-branch deletion with `git branch -d`.

Finally it deletes everything `wt` placed in the lane root: entries named like
an entry in `.wt/lane_root/`, the `.code-workspace` file, and `.idea/`, template
or not. `.idea/` is IDE state the IDE rebuilds — window layout, open files,
recent searches, breakpoints, run configurations you created without saving
them to the template — so it is not listed, apart from shelved changes. Other
files `wt` did not place — a `.tmp/` directory, notes an agent wrote — stay.
Cleanup lists them and prints an `rm -rf` line for the lane; the `.wt-lane`
marker stays until then, so the directory is still recognisable as a lane.

Not covered: Git-ignored files inside a worktree that did not come from a
template — a local `.env`, build output. Git does not report them as changes, so
they are deleted with the worktree without a warning. Copy out anything you need
first.

## Security notes

### `.wt/workspace.sh` executes shell code

The workspace marker is sourced, so it can execute arbitrary commands. Use it only inside workspaces you control.

Avoid placing the tool in directories containing untrusted projects that may supply a `.wt/workspace.sh`.

### Templates are copied into every lane

Anything in `.wt/lane_root/` and `.wt/repos/` lands in every new lane. Keep credentials out of
templates — export them from your shell profile, or use `${VAR:-placeholder}`
in a template `.envrc` so an existing export wins.
