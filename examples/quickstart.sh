#!/usr/bin/env bash
# quickstart.sh — build a throwaway wt workspace and create a demo lane.
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
cp "$EXAMPLE/.wt-workspace" .
cp -r "$EXAMPLE/.wt-templates" .
cp "$EXAMPLE/checkout-api/.wt-include" checkout-api/

# Local, Git-ignored config referenced by checkout-api/.wt-include.
# The .gitignore is committed so it also applies inside lane worktrees; the
# files themselves stay untracked and are carried into lanes by .wt-include.
mkdir -p checkout-api/config
printf 'export API_TOKEN=local-dev\n' >checkout-api/.envrc
printf 'featureFlags:\n  giftCards: true\n' >checkout-api/config/local.yaml
printf '.envrc\nconfig/local.yaml\n' >checkout-api/.gitignore
git -C checkout-api add .gitignore
git -C checkout-api -c user.name=wt-demo -c user.email=wt-demo@example.com \
  -c commit.gpgsign=false commit -q -m "ignore local config"

echo
echo ">> wt create demo-lane"
"$WT" create demo-lane

echo
echo ">> wt list"
"$WT" list

LANE=$("$WT" path demo-lane)

cat <<EOF

Demo workspace left in place for inspection:
  $WS

Things to look at:
  ls $LANE
  cat "$LANE/AGENTS.md"                        # generated lane guide
  cat "$LANE/HANDOVER.md"                      # from .wt-templates/_lane
  cat "$LANE/checkout-api/config/local.yaml"   # copied via .wt-include
  cat "$LANE/checkout-api/.envrc"              # live include wins over template

When you are done:
  (cd "$WS" && "$WT" cleanup demo-lane)
  rm -rf "$WORKDIR"
EOF
