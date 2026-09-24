# Oracle VM (`fare-collector-micro`, ap-mumbai-1)

## Heartbeat (active)

GitHub often skips scheduled workflow runs, so the VM starts the watchdog instead.
`heartbeat.timer` runs `heartbeat.sh` every 10 min. It force-pushes a fresh
empty commit to the `heartbeat` branch with the VM's deploy key, and each push
triggers `.github/workflows/watchdog.yml`. The watchdog restarts the Actions
collector if `runs.ndjson` has had no new run for 75 min.

    systemctl list-timers heartbeat.timer
    journalctl -u heartbeat -n 20

## Collector (disabled)

Tried on 2026-09-24 as the primary collector. Google blocked the VM's IP on the
first request, so `collector.timer` is disabled and GitHub Actions collects.
The files still work on a host whose IP Google doesn't block (for example a
machine on a home connection):

- `setup.sh`: run as root (expects the other files in `/tmp`). Installs Node 20,
  2 GB swap, a `collector` user with two deploy keys (`id_app` read-only on
  fraktosh/flightmax, `id_data` write on this repo).
- `run.sh`: one pass (collect 25 min, train, status page, push).
- `collector.timer`: starts the next pass 2 min after the previous one ends.
- `/etc/collector.password` holds `DASHBOARD_PASSWORD`, raw, mode 600. It must
  match the password the models were encrypted with, or train.ts rebuilds them.

Don't run the collector alongside the Actions chain: both would push state.json.
