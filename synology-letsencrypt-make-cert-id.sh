#!/bin/bash -e

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

CERT_ID_PATH="$1"
ARCHIVE_PATH="$2"

cert_id=""
if [[ -s $CERT_ID_PATH ]]; then
    source "$CERT_ID_PATH"
fi

mkdir -p "$ARCHIVE_PATH"

if [[ -z $cert_id ]]; then
    archive_cert_path=$(mktemp -d "$ARCHIVE_PATH"/XXXXXX)
    cert_id="${archive_cert_path##*/}"
    printf 'cert_id=%s' "$cert_id" > "$CERT_ID_PATH"
fi

mkdir -p "$ARCHIVE_PATH/$cert_id"

info="$ARCHIVE_PATH/INFO"
if [[ -s $info ]]; then
    has_cert_id="$(jq --arg cert_id "$cert_id" 'has($cert_id)' "$info")"

    if [[ $has_cert_id != true ]]; then
        # append
        tmp_info=$(mktemp)
        jq --arg cert_id "$cert_id" '.[$cert_id] = { desc: "", services: [] }' < "$info" > "$tmp_info" \
            && \mv "$tmp_info" "$info"
    fi
else
  # create
  jq -n --arg cert_id "$cert_id" '{ ($cert_id) : { desc: "", services: [] } }' > "$info"
fi

