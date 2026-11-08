#!/usr/bin/env bash
# run.sh [wt-script] — end-to-end tests for wt in throwaway workspaces.
# Exits non-zero if any check fails.

set -uo pipefail

W=${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/wt}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/wt-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
WS=$TMP/ws
L=$WS/.worktrees
FAILED=0

mk() {
  rm -rf "$WS"
  mkdir -p "$WS/r" "$WS/.wt"
  touch "$WS/.wt/workspace.sh"
  git -C "$WS/r" init -q -b main
  git -C "$WS/r" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}
tmpl() { mkdir -p "$(dirname "$WS/.wt/$1")"; echo "$2" >"$WS/.wt/$1"; }
ignore() {
  echo "$1" >>"$WS/r/.gitignore"
  git -C "$WS/r" add .gitignore
  git -C "$WS/r" -c user.name=t -c user.email=t@t commit -qm ignore
}
r() { (cd "$WS" && "$W" "$@" 2>&1 </dev/null); }
# run with a terminal on stdin (util-linux script), answering $1 to the prompt
rtty() { local a=$1; shift; (cd "$WS" && printf '%s\n' "$a" | script -qec "$W $*" /dev/null 2>&1); }
ok() {
  local d=$1
  shift
  if "$@"; then
    echo "  PASS $d"
  else
    echo "  FAIL $d"
    FAILED=$((FAILED + 1))
  fi
}
skip() { echo "  SKIP $1"; }
listed() { r list | grep -q "^$1 "; }
has() { grep -q "$1" "$2"; }
gone() { test ! -e "$L/$1"; }

echo "## cleanup removes everything wt placed"
mk; tmpl lane_root/AGENTS.md guide; tmpl lane_root/.idea/x.xml t
r create a >/dev/null; echo ide >"$L/a/.idea/workspace.xml"; r cleanup a >/dev/null
ok "untouched lane + IDE state removed without prompt" gone a
mk; r create a >/dev/null; mkdir "$L/a/.idea"; echo ide >"$L/a/.idea/workspace.xml"; r cleanup a >/dev/null
ok ".idea without a template removed" gone a
mk; r create x/y >/dev/null; r cleanup x/y >/dev/null
ok "empty parent directories removed" gone x
mk; r create i >/dev/null; printf '.wt-lane\n' >"$L/i/.wt-lane-manifest"; r cleanup i >/dev/null
ok "manifest from older versions removed" gone i

echo "## edited copies are listed and need confirmation"
mk; tmpl lane_root/AGENTS.md guide; r create a >/dev/null; echo n >>"$L/a/AGENTS.md"; out=$(r cleanup a)
ok "edited lane template copy listed" grep -q 'AGENTS.md (edited template copy)' <<<"$out"
ok "no terminal: nothing removed" test -d "$L/a/r"
if script -qec true /dev/null >/dev/null 2>&1; then
  rtty n cleanup a >/dev/null
  ok "answer n: nothing removed" test -f "$L/a/AGENTS.md"
  rtty y cleanup a >/dev/null
  ok "answer y: lane removed" gone a
else
  skip "confirmation prompt (needs util-linux script)"
fi
mk; r create a >/dev/null; echo x >>"$L/a/a.code-workspace"; out=$(r cleanup a)
ok "edited .code-workspace listed" grep -q 'a.code-workspace (edited)' <<<"$out"
mk; tmpl lane_root/.idea/x.xml t; r create a >/dev/null; echo changed >"$L/a/.idea/x.xml"; out=$(r cleanup a)
ok "edited file inside a templated directory listed" grep -q '.idea/x.xml (edited template copy)' <<<"$out"
mk; tmpl 'lane_root/docs/notes and todo.md' t; r create a >/dev/null; echo e >>"$L/a/docs/notes and todo.md"; out=$(r cleanup a)
ok "edited copy with ' and ' in its name listed by its full path" grep -qF 'docs/notes and todo.md (edited template copy)' <<<"$out"
mk; tmpl lane_root/docs/README.md t; r create a >/dev/null; echo d >"$L/a/docs/DESIGN.md"; out=$(r cleanup a)
ok "file added inside a templated directory listed" grep -q 'docs/DESIGN.md (added to a template copy)' <<<"$out"
ok "no terminal: added file kept" test -f "$L/a/docs/DESIGN.md"
mk; r create a >/dev/null; mkdir -p "$L/a/.idea/shelf"; echo patch >"$L/a/.idea/shelf/x.patch"; out=$(r cleanup a)
ok "shelved IDE changes listed" grep -q '.idea/shelf (shelved IDE changes)' <<<"$out"

echo "## worktree changes"
mk; r create a >/dev/null; echo code >"$L/a/r/new.go"; out=$(r cleanup a)
ok "uncommitted file listed" grep -q 'r/new.go (uncommitted)' <<<"$out"
ok "no terminal: worktree kept" test -f "$L/a/r/new.go"
mk; tmpl repos/r/.vscode/settings.json '{}'; r create a >/dev/null; r cleanup a >/dev/null
ok "untouched untracked template copy does not prompt" gone a
mk; tmpl repos/r/.vscode/settings.json '{}'; r create a >/dev/null
echo '{"x":1}' >"$L/a/r/.vscode/settings.json"; out=$(r cleanup a)
ok "edited untracked template copy listed once" test "$(grep -c 'settings.json' <<<"$out")" -eq 1
mk; ignore .envrc; tmpl repos/r/.envrc 'export A=1'; r create a >/dev/null
echo 'export A=2' >"$L/a/r/.envrc"; out=$(r cleanup a)
ok "edited ignored template copy listed" grep -q 'r/.envrc (edited template copy)' <<<"$out"
mk; ignore s.env; r create a >/dev/null; echo X >"$L/a/r/s.env"; r cleanup a >/dev/null
ok "other ignored files go without a prompt (documented)" gone a
mk; r create a >/dev/null
git -C "$L/a/r" -c user.name=t -c user.email=t@t commit -q --allow-empty -m wip; r cleanup a >/dev/null
ok "unmerged branch kept" git -C "$WS/r" show-ref --verify --quiet refs/heads/a

echo "## files wt did not place stay"
mk; r create a >/dev/null; mkdir "$L/a/.tmp"; echo p >"$L/a/.tmp/PLAN.md"; out=$(r cleanup a)
ok ".tmp kept" test -f "$L/a/.tmp/PLAN.md"
ok "kept entries listed" grep -q '^  .tmp$' <<<"$out"
ok "marker kept while the lane has files" test -f "$L/a/.wt-lane"
ok "worktree removed anyway" test ! -e "$L/a/r"

echo "## create"
mk; out=$(r create d)
ok "failed fetch announced" grep -q 'could not fetch' <<<"$out"
ok "fallback to HEAD announced" grep -q 'branching from its current HEAD' <<<"$out"
mk; out=$(r create j)
ok "missing templates announced" grep -q 'no .wt/lane_root/ or .wt/repos/' <<<"$out"
mk; mkdir "$WS/bad"; git -C "$WS/bad" init -q; r create b r bad >/dev/null
ok "partially created lane visible in list" listed b
mk; r create c 'x/y' >/dev/null
ok "invalid repo argument leaves no lane dir" gone c
mk; mkdir "$WS/plain"; r create e plain >/dev/null
ok "no worktree created leaves no lane dir" gone e
mk; r create foo/bar >/dev/null; out=$(r create foo)
ok "lane around an existing lane refused" grep -q "contains lane 'foo/bar'" <<<"$out"
ok "no stray marker left around it" test ! -e "$L/foo/.wt-lane"
ok "inner lane still listed" listed foo/bar
mk; r create foo >/dev/null; out=$(r create foo/bar)
ok "lane inside an existing lane refused" grep -q "inside lane 'foo'" <<<"$out"
mk; r create feat/a >/dev/null; out=$(r cleanup feat)
ok "cleanup of a directory that is not a lane refused" grep -q 'is not a lane' <<<"$out"
ok "lanes below it untouched" test -d "$L/feat/a/r"
mk; tmpl repos/r/.vscode/settings.json '{}'; r create a >/dev/null; rm "$L/a/a.code-workspace"
REAL_CP=$(command -v cp)
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\n"%s" "$@"; s=$?\ncase " $* " in *" -rn "*) exit 1 ;; esac\nexit $s\n' "$REAL_CP" >"$TMP/bin/cp"
chmod +x "$TMP/bin/cp"
(cd "$WS" && PATH="$TMP/bin:$PATH" "$W" create a >/dev/null 2>&1)
ok "repair survives cp -n exiting 1 (coreutils 9.2-9.4)" test -f "$L/a/a.code-workspace"
mk; tmpl lane_root/AGENTS.md guide; r create h >/dev/null; echo mine >>"$L/h/AGENTS.md"; r create h >/dev/null
ok "rerun keeps an edited file" has mine "$L/h/AGENTS.md"
rm "$L/h/AGENTS.md"; r create h >/dev/null
ok "rerun restores a deleted template file" test -f "$L/h/AGENTS.md"

echo "## layout and list"
mk; rm -r "$WS/.wt"; touch "$WS/.wt-workspace"; out=$(r list)
ok "old layout stops with migration commands" grep -q 'mv .wt-workspace .wt/workspace.sh' <<<"$out"
mk; mkdir -p "$WS/r/.wt"; (cd "$WS/r" && "$W" create z r >/dev/null 2>&1)
ok "a repo's own .wt/ is not taken as the workspace root" test -d "$L/z/r"
mk; r create p/b/c/d/e/f/g >/dev/null
ok "deeply nested lane listed" listed p/b/c/d/e/f/g
echo
if [ "$FAILED" -gt 0 ]; then
  echo "$FAILED failed"
  exit 1
fi
echo "all passed"
