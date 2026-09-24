#!/usr/bin/env bash
# Pokes the GitHub watchdog: force-pushes a fresh commit to the `heartbeat`
# branch, which triggers watchdog.yml (on: push). GitHub reads push-triggered
# workflows from the pushed commit, so the commit holds only main's
# .github/workflows/watchdog.yml. Uses the VM's existing deploy key.
set -euo pipefail
cd /opt/collector/data
git fetch -q origin main
# Keep the checkout current too; Caddy serves it as the public dashboard.
git reset -q --hard origin/main
wf=$(git rev-parse origin/main:.github/workflows/watchdog.yml)
t=$(printf '100644 blob %s\twatchdog.yml\n' "$wf" | git mktree)
t=$(printf '040000 tree %s\tworkflows\n' "$t" | git mktree)
t=$(printf '040000 tree %s\t.github\n' "$t" | git mktree)
commit=$(GIT_AUTHOR_NAME=heartbeat GIT_AUTHOR_EMAIL=heartbeat@users.noreply.github.com \
  GIT_COMMITTER_NAME=heartbeat GIT_COMMITTER_EMAIL=heartbeat@users.noreply.github.com \
  git commit-tree "$t" -m "watchdog heartbeat $(date -u +%FT%TZ)")
git push -qf origin "$commit:refs/heads/heartbeat"
