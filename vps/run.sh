#!/usr/bin/env bash
# One collection pass: collect, train, rebuild the status page, push.
# Started by collector.timer 2 minutes after the previous pass ends.
set -uo pipefail
cd /opt/collector
exec 9>/tmp/collector.lock
flock -n 9 || { echo "another pass is running"; exit 0; }
export DASHBOARD_PASSWORD="$(cat /etc/collector.password 2>/dev/null)"

# Pick up anything the GitHub Actions fallback pushed, and the latest code.
git -C data pull --quiet --rebase -X theirs || { git -C data rebase --abort 2>/dev/null; git -C data fetch -q && git -C data reset -q --hard origin/main; }
git -C app fetch --quiet && git -C app reset --quiet --hard origin/main
if ! cmp -s app/package-lock.json .lock-installed; then
  (cd app && npm ci --no-audit --no-fund --silent) && cp app/package-lock.json .lock-installed
fi

cd app
COLLECTOR_MINUTES=${COLLECTOR_MINUTES:-25} npx tsx collector/run.ts --store ../data; collect=$?
npx tsx collector/train.ts --store ../data
npx tsx collector/status.ts --store ../data && cp collector/site/index.html ../data/index.html

cd ../data
git add -A
if ! git diff --cached --quiet; then
  git commit --quiet -m "data: $(tail -n 1 runs.ndjson | cut -c1-120)"
  for i in 1 2 3 4 5; do
    git pull --quiet --rebase -X theirs && git push --quiet && exit $collect
    sleep $((i * 10))
  done
  exit 1
fi
exit $collect
