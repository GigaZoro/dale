#!/bin/sh
# Brings this fork's main up to date with lubluniky/dale main, pushes it to
# GigaZoro/dale, and refreshes the Claude Code and Codex installs on this machine.
# Also the way to ship your own edits: commit on main, then run this.
# Exit 3 means the upstream merge conflicted: resolve it keeping our changes,
# commit, and run this again.
set -eu
cd "$(dirname "$0")/.."

[ "$(git branch --show-current)" = main ] || { echo "error: not on main" >&2; exit 2; }
[ -z "$(git status --porcelain)" ] || { echo "error: working tree has uncommitted changes" >&2; exit 2; }

git fetch --quiet upstream
git fetch --quiet origin
git merge --ff-only --quiet origin/main

if git merge-base --is-ancestor upstream/main HEAD; then
    echo "already contains upstream/main ($(git rev-parse --short upstream/main))"
elif ! git merge --no-edit upstream/main; then
    echo "error: merge conflict with upstream/main; resolve it, commit, and rerun" >&2
    exit 3
fi
git push --quiet origin main
echo "fork main is $(git rev-parse --short HEAD)"

codex="$(command -v codex || ls -d "$HOME"/.t3/tools/codex/*/bin/codex 2>/dev/null | sort -V | tail -n 1)"
[ -x "$codex" ] || { echo "error: codex CLI not found" >&2; exit 4; }

claude plugin marketplace update dale
claude plugin update dale@dale --scope user
"$codex" plugin marketplace upgrade dale
"$codex" plugin add dale@dale
