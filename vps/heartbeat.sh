#!/usr/bin/env bash
# Pokes the GitHub watchdog: force-pushes a fresh empty commit to the
# `heartbeat` branch, which triggers watchdog.yml (on: push). Uses the VM's
# existing deploy key, so no extra token is needed.
set -euo pipefail
dir=/opt/collector/heartbeat
if [ ! -d "$dir/.git" ]; then
  git init -q "$dir"
  git -C "$dir" remote add origin github-data:fraktosh/flightmax-data.git
fi
cd "$dir"
tree=$(git mktree </dev/null)
commit=$(GIT_AUTHOR_NAME=heartbeat GIT_AUTHOR_EMAIL=heartbeat@users.noreply.github.com \
  GIT_COMMITTER_NAME=heartbeat GIT_COMMITTER_EMAIL=heartbeat@users.noreply.github.com \
  git commit-tree "$tree" -m "watchdog heartbeat $(date -u +%FT%TZ)")
git push -qf origin "$commit:refs/heads/heartbeat"
