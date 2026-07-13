#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /usr/local/bin/synology-letsencrypt-lib.sh

cert_id="$(makeCertId)"
deployToArchive "$cert_id"
reloadServices "$cert_id"
