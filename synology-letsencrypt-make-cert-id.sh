#!/bin/bash -e

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

archive_path="/usr/syno/etc/certificate/_archive"
info="$archive_path/INFO"

mkdir -p "$archive_path"
cert_path=$(mktemp -d "$archive_path"/XXXXXX)
cert_id="${cert_path##*/}"

if [[ -s $info ]]; then
    # append
    tmp_info=$(mktemp)
    jq --arg cert_id "$cert_id" '.[$cert_id] = { desc: "", services: [] }' < "$info" > "$tmp_info" \
        && \mv "$tmp_info" "$info"
else
  # create
  jq -n --arg cert_id "$cert_id" '{ ($cert_id) : { desc: "", services: [] } }' > "$info"
fi

echo "cert_id=$cert_id"
