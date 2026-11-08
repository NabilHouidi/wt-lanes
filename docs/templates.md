# Customizing lanes

Everything `wt` places into a lane beyond the worktrees themselves: templates,
the lane guide, the generated lane files, and IDE setup.

- [Templates](#templates)
- [Lane guide](#lane-guide)
- [Generated lane files](#generated-lane-files)
- [IDE behavior](#ide-behavior)

## Templates

Templates are optional. Without `.wt/lane_root/` or `.wt/repos/`, `wt create`
says so (`note: no .wt/lane_root/ or .wt/repos/ in …`) and the lane gets only
its worktrees and generated files.

```text
.wt/
├── lane_root/
└── repos/
    ├── checkout-api/
    └── checkout-web/
```

Templates are copied, never linked, and copying never overwrites a file the lane
already has. A rerun of `wt create <feature> <repos…>` copies whatever is
missing. To pick up a changed template in an existing lane, delete the lane's
copy and rerun.

### Lane templates

```text
.wt/lane_root/
```

Contents are copied to the root of each feature lane.

Examples:

```text
.wt/lane_root/
├── AGENTS.md
├── HANDOVER.md
├── DESIGN.md
├── .envrc
├── .idea/
├── .run/
└── .vscode/
```

Top-level files whose names end in `.tmpl` are not copied.

Existing directories are merged without replacing existing files.

Do not name a lane template directory after a repository (for example, `.wt/lane_root/checkout-api`). Because repositories are also lane subdirectories, such a template can be merged into the repository worktree.

`wt cleanup` deletes lane template copies with the lane, and asks first when one
no longer matches its template; see [Cleanup behavior](safety-and-cleanup.md#cleanup-behavior).

### Repository templates

```text
.wt/repos/checkout-api/
```

Contents are copied into the newly created `checkout-api` worktree for a lane.

Examples:

```text
.wt/repos/checkout-api/
├── .vscode/
├── .run/
├── .envrc
└── config/
    └── local.yaml
```

On a new worktree, template files are written over whatever the branch
checked out at the same path. When a valid worktree already exists, rerunning
`wt create` copies only missing files.

Consider ignoring these files in the repository (for example in its
`.gitignore`); otherwise they show up as untracked changes in `git status` and
`wt list`. Either way, `wt cleanup` deletes untouched copies with the worktree
and asks before deleting edited ones.

## Lane guide

A lane guide for AI coding agents is an ordinary lane template: put
`AGENTS.md`, `CLAUDE.md`, or both in `.wt/lane_root/`, and every lane gets
a copy. `wt` does not generate one.

Good content for it: the rule to edit only inside the lane, how to run each
repository's tests, and where lane notes belong (`HANDOVER.md`, `.tmp/`) — so
agents do not edit the guide itself. Cleanup asks before deleting an edited
guide, like any other changed template copy. See
[`examples/commerce-workspace`](../examples/commerce-workspace/.wt/lane_root/AGENTS.md)
for a starting point.

## Generated lane files

### `.wt-lane`

Contains the feature name. It identifies the directory as a lane and helps `wt list` find lanes regardless of nesting depth. Tools can walk up from any file to the nearest `.wt-lane` to find the lane root.

`wt create` writes it before creating worktrees, so a create that fails partway
still leaves a lane that `wt list` and `wt cleanup` can see.

### `<feature-name>.code-workspace`

A VS Code workspace containing one folder: the lane root.

Repository subfolders and lane documentation are reachable from that root. Each lane receives a deterministic title and status-bar color based on the feature name.

An existing workspace file is never overwritten, so local customizations stay.
Cleanup deletes it with the lane, asking first if it was edited.

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

Shared VS Code settings come from templates: `.wt/lane_root/.vscode/` lands in the lane root, `.wt/repos/<repo>/.vscode/` in each repository worktree.

### JetBrains

JetBrains support is provided through templates. If present, `.wt/lane_root/.idea` is copied or merged into the lane root. Per-repository `.idea` or `.run` content can be supplied the same way through `.wt/repos/<repo>/`.

If the resulting lane has `.idea` but no `.idea/.name`, `wt` creates `.name` using the workspace root’s directory name. Existing IDE files are never replaced.

Cleanup deletes `.idea/` with the lane, including the state the IDE wrote there
(`workspace.xml`, breakpoints, run configurations you added). It asks first only
about edited template files and shelved changes (`.idea/shelf/`) — save a run
configuration you want to keep into `.wt/lane_root/.idea/` first.
