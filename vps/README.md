# Oracle VM collector

Primary collector. Runs on an Oracle Cloud Always Free VM (`fare-collector-micro`,
ap-mumbai-1, VM.Standard.E2.1.Micro, Ubuntu 24.04). GitHub Actions is the fallback:
`watchdog.yml` starts `collect.yml` when `runs.ndjson` hasn't had a new run for 75 min.

- `setup.sh`: run as root on a fresh VM (expects the other files in `/tmp`).
  Installs Node 20, 2 GB swap, a `collector` user with two deploy keys
  (`id_app` read-only on fraktosh/flightmax, `id_data` write on this repo).
- `run.sh`: one pass (collect 25 min, train, status page, push). Installed at
  `/opt/collector/run.sh`.
- `collector.timer`: starts the next pass 2 min after the previous one ends.
- `/etc/collector.password` on the VM holds `DASHBOARD_PASSWORD`, raw, mode 600. Not in git.

Useful commands on the VM:

    systemctl list-timers collector.timer
    journalctl -u collector -n 50
    sudo systemctl start collector      # run a pass now
    sudo systemctl disable --now collector.timer   # stop collecting here
