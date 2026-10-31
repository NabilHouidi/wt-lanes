# Examples

`commerce-workspace/` is a model `wt` workspace you can copy pieces from, and
`quickstart.sh` builds a throwaway copy of it with real Git repositories so you
can watch `wt` work without touching your own projects.

## Try it

```bash
examples/quickstart.sh
```

The script creates three scratch repositories in a temp directory, applies the
example configuration, and runs `wt create` and `wt list`. The directory is left
behind so you can inspect the lane and run `wt cleanup` yourself.

## Layout

```text
commerce-workspace/
├── .wt-workspace                     # pinned repo list + default base branch
├── .wt-templates/
│   ├── _lane/                        # copied into every lane root
│   │   ├── HANDOVER.md               # handover note; survives cleanup
│   │   └── .envrc                    # per-lane compose project name (direnv)
│   ├── checkout-api/                 # copied into checkout-api worktrees
│   │   ├── .envrc
│   │   └── .vscode/settings.json
│   └── checkout-web/
│       └── .vscode/settings.json
└── checkout-api/
    └── .wt-include                   # Git-ignored files to copy into lanes
```

## What each piece demonstrates

| File | Demonstrates |
| --- | --- |
| `.wt-workspace` | Pinning `REPOS`, setting `DEFAULT_BASE`, and the commented `LANE_GUIDE` knob. |
| `_lane/HANDOVER.md` | Lane-level templates. Once you edit the copied file, `wt cleanup` treats it as yours and preserves it. |
| `_lane/.envrc` | Lane-level environment; `wt` runs `direnv allow` after copying it. |
| `checkout-api/.envrc` (template) | Repository templates. Note the interplay below. |
| `checkout-api/.wt-include` | Live ignored configuration: `.envrc` and `config/local.yaml` are copied from the main checkout into each lane. |

Template versus live include: `checkout-api` has a template `.envrc` *and* lists
`.envrc` in `.wt-include`. Live includes are applied after templates and win, so
lane worktrees end up with the main checkout’s `.envrc`. This matches the
documented rule: on a newly created worktree, live includes overwrite template
files.

## Use it in your own workspace

```bash
cp examples/commerce-workspace/.wt-workspace /path/to/your/workspace/
cp -r examples/commerce-workspace/.wt-templates /path/to/your/workspace/
```

Then adjust `REPOS` (or delete it to auto-discover repositories) and create a
`.wt-include` in each main repository that needs local configuration carried
into lanes.
