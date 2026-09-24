# Oracle VM collector (disabled)

Tried on 2026-09-24 as the primary collector on an Oracle Cloud Always Free VM
(`fare-collector-micro`, ap-mumbai-1). Google blocked the VM's IP on the first
request, so the timer is disabled and GitHub Actions is the collector again.

The files here still work on a host whose IP Google doesn't block (for example
a machine on a home connection):

- `setup.sh`: run as root (expects the other files in `/tmp`). Installs Node 20,
  2 GB swap, a `collector` user with two deploy keys (`id_app` read-only on
  fraktosh/flightmax, `id_data` write on this repo).
- `run.sh`: one pass (collect 25 min, train, status page, push).
- `collector.timer`: starts the next pass 2 min after the previous one ends.
- `/etc/collector.password` holds `DASHBOARD_PASSWORD`, raw, mode 600. It must
  match the password the models were encrypted with, or train.ts rebuilds them.

Don't run it alongside the Actions chain: both would push state.json.
