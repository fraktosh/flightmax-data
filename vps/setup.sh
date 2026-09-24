#!/usr/bin/env bash
# Runs on the VM as root. Installs Node 20 and the collector service.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl ca-certificates >/dev/null
if ! node -v 2>/dev/null | grep -q '^v20'; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
  apt-get install -y -qq nodejs >/dev/null
fi
id collector >/dev/null 2>&1 || useradd -m -s /bin/bash collector
install -d -o collector -g collector -m 700 /home/collector/.ssh /opt/collector
# 1 GB RAM: add swap so npm ci and training don't get OOM-killed.
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap -q /swapfile && swapon /swapfile
  grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
[ -f /etc/collector.password ] || install -m 600 -o collector -g collector /dev/null /etc/collector.password
su - collector -c 'test -f ~/.ssh/id_app || ssh-keygen -q -t ed25519 -N "" -C collector-app -f ~/.ssh/id_app
test -f ~/.ssh/id_data || ssh-keygen -q -t ed25519 -N "" -C collector-data -f ~/.ssh/id_data
cat > ~/.ssh/config <<CFG
Host github-app
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_app
  IdentitiesOnly yes
Host github-data
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_data
  IdentitiesOnly yes
CFG
ssh-keyscan -t ed25519,rsa,ecdsa github.com >> ~/.ssh/known_hosts 2>/dev/null'
install -m 755 -o collector -g collector /tmp/run.sh /opt/collector/run.sh
install -m 644 /tmp/collector.service /tmp/collector.timer /etc/systemd/system/
systemctl daemon-reload
echo SETUP_DONE
