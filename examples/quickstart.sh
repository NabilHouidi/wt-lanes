#!/usr/bin/env bash
# quickstart.sh — build a throwaway wt workspace and create demo lanes.
#
# Nothing touches your real projects: everything happens in a temp directory
# that is left behind so you can inspect it (and remove it yourself).

set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WT="$REPO_ROOT/wt"
EXAMPLE="$REPO_ROOT/examples/commerce-workspace"

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/wt-demo.XXXXXX")
WS="$WORKDIR/commerce-workspace"
mkdir -p "$WS"
cd "$WS"

echo ">> building scratch workspace in $WS"

for repo in checkout-api checkout-web shared-events; do
  git init -q --initial-branch=main "$repo" 2>/dev/null || git init -q "$repo"
  git -C "$repo" -c user.name=wt-demo -c user.email=wt-demo@example.com \
    -c commit.gpgsign=false commit -q --allow-empty -m "initial commit"
done

# Example configuration: pinned repo list, default base, templates.
cp -r "$EXAMPLE/.wt" .

# Template files are Git-ignored so they do not show up as changes in lane
# worktrees.
for repo in checkout-api checkout-web; do
  printf '.envrc\n.vscode/\n' >"$repo/.gitignore"
  git -C "$repo" add .gitignore
  git -C "$repo" -c user.name=wt-demo -c user.email=wt-demo@example.com \
    -c commit.gpgsign=false commit -q -m "ignore local editor and env files"
done

# Lane names double as branch names, so hierarchy works: related lanes group
# under .worktrees/<prefix>/, and each repo subset gets its own leaf.
echo
echo ">> wt create feat/gift-card-checkout              (all repos)"
"$WT" create feat/gift-card-checkout

echo
echo ">> wt create hotfix/1.2.4-double-charge checkout-api"
"$WT" create hotfix/1.2.4-double-charge checkout-api

echo
echo ">> wt create review/pr-1234 checkout-web shared-events"
"$WT" create review/pr-1234 checkout-web shared-events

echo
echo ">> lane hierarchy under .worktrees/"
if command -v tree >/dev/null 2>&1; then
  tree -L 3 .worktrees
else
  find .worktrees -mindepth 1 -maxdepth 3 | sort
fi

echo
echo ">> wt list"
"$WT" list

LANE=$("$WT" path feat/gift-card-checkout)

cat <<EOF

Demo workspace left in place for inspection:
  $WS

Things to look at:
  cat "$LANE/AGENTS.md"                        # lane guide, from .wt/lane_root
  cat "$LANE/HANDOVER.md"                      # from .wt/lane_root
  cat "$LANE/checkout-api/.envrc"              # from .wt/repos/checkout-api
  ls "$LANE"                                   # gift-card-checkout.code-workspace

Branch names mirror the lane names in every repository:
  git -C "$WS/checkout-api" branch --list

When you are done:
  (cd "$WS" && "$WT" cleanup feat/gift-card-checkout)
  (cd "$WS" && "$WT" cleanup hotfix/1.2.4-double-charge)
  (cd "$WS" && "$WT" cleanup review/pr-1234)   # empty parent dirs are pruned
  rm -rf "$WORKDIR"
EOF
