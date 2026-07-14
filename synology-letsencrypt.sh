#!/bin/bash
set -euo pipefail

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

exec /usr/local/bin/lego --config /usr/local/etc/synology-letsencrypt/lego.yml "$@"
