# Examples

`commerce-workspace/` is a model `wt` workspace you can copy pieces from, and
`quickstart.sh` builds a throwaway copy of it with real Git repositories so you
can watch `wt` work without touching your own projects.

## Try it

```bash
examples/quickstart.sh
```

The script creates three scratch repositories in a temp directory, applies the
example configuration, and creates three lanes with hierarchical names. The
directory is left behind so you can inspect the lanes and run `wt cleanup`
yourself.

## What the demo creates

Lane names double as branch names, so hierarchy works — related lanes group
under `.worktrees/<prefix>/`, and each lane can cover a different subset of
repositories:

```text
.worktrees/
├── feat/
│   └── gift-card-checkout/       # all three repositories
├── hotfix/
│   └── 1.2.4-double-charge/      # checkout-api only
└── review/
    └── pr-1234/                  # checkout-web + shared-events
```

Each leaf is a full lane: repository worktrees on a branch matching the lane
name, a generated `<name>.code-workspace`, and the `lane_root` template files
(`AGENTS.md`, `HANDOVER.md`, `.envrc`). `wt list` prints the full lane names, and `wt cleanup` prunes
empty parent directories, so `.worktrees/feat/` disappears with its last lane.

## Layout

```text
commerce-workspace/
└── .wt/
    ├── workspace.sh                  # pinned repo list + default base branch
    ├── lane_root/                    # copied into every lane root
    │   ├── AGENTS.md                 # lane guide for AI coding agents
    │   ├── HANDOVER.md               # handover note; cleanup asks before deleting it once filled in
    │   └── .envrc                    # per-lane compose project name (direnv)
    └── repos/
        ├── checkout-api/             # copied into checkout-api worktrees
        │   ├── .envrc
        │   └── .vscode/settings.json
        └── checkout-web/
            └── .vscode/settings.json
```

## What each piece demonstrates

| File | Demonstrates |
| --- | --- |
| `.wt/workspace.sh` | Pinning `REPOS` and setting `DEFAULT_BASE`. |
| `lane_root/AGENTS.md` | The lane guide is an ordinary template; rename or copy it to `CLAUDE.md` for Claude Code. |
| `lane_root/HANDOVER.md` | Lane-level templates. Once you edit the copied file, `wt cleanup` lists it and asks before deleting it. |
| `lane_root/.envrc` | Lane-level environment; `wt` runs `direnv allow` after copying it. |
| `repos/checkout-api/.envrc`, `repos/*/.vscode/` | Repository templates, copied into each new worktree of that repository. |

`quickstart.sh` adds `.envrc` and `.vscode/` to the demo repositories'
`.gitignore`, so the template copies do not show up as untracked changes.

## Use it in your own workspace

```bash
cp -r examples/commerce-workspace/.wt /path/to/your/workspace/
```

Then adjust `REPOS` in `.wt/workspace.sh` (or delete it to auto-discover
repositories), rename the directories under `.wt/repos/` to your repositories,
and make sure each
repository ignores the files its template adds.
