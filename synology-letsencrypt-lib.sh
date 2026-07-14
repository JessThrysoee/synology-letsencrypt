#!/bin/bash
set -euo pipefail

ARCHIVE_PATH="/usr/syno/etc/certificate/_archive"

makeCertId() {
    local cert_id_path="${LEGO_HOOK_CERT_PATH%.crt}.cert_id"

    local cert_id=""
    if [[ -s $cert_id_path ]]; then
        # shellcheck disable=SC1090
        source "$cert_id_path"
    fi

    mkdir -p "$ARCHIVE_PATH"

    if [[ -z $cert_id ]]; then
        local archive_cert_path
        archive_cert_path=$(mktemp -d "$ARCHIVE_PATH"/XXXXXX)
        cert_id="${archive_cert_path##*/}"
        printf 'cert_id=%s' "$cert_id" > "$cert_id_path"
    fi

    mkdir -p "$ARCHIVE_PATH/$cert_id"

    local info="$ARCHIVE_PATH/INFO"
    if [[ -s $info ]]; then
        local has_cert_id
        has_cert_id="$(jq --arg cert_id "$cert_id" 'has($cert_id)' "$info")"

        if [[ $has_cert_id != true ]]; then
            # append
            local tmp_info
            tmp_info=$(mktemp)
            trap 'rm -f "$tmp_info"' RETURN
            jq --arg cert_id "$cert_id" '.[$cert_id] = { desc: "", services: [] }' < "$info" > "$tmp_info" \
                && \mv "$tmp_info" "$info"
        fi
    else
        # create
        jq -n --arg cert_id "$cert_id" '{ ($cert_id) : { desc: "", services: [] } }' > "$info"
    fi

    printf '%s' "$cert_id"
}

deployToArchive() {
    local cert_id="$1"
    local dest="$ARCHIVE_PATH/$cert_id"

    # extract leaf cert (handle both lego bundle modes)
    openssl x509 -in "$LEGO_HOOK_CERT_PATH" > "$dest/cert.pem"
    cp "$LEGO_HOOK_CERT_KEY_PATH" "$dest/privkey.pem"
    cp "$LEGO_HOOK_ISSUER_CERT_PATH" "$dest/chain.pem"
    cat "$dest/cert.pem" "$LEGO_HOOK_ISSUER_CERT_PATH" > "$dest/fullchain.pem"

    chmod 400 "$dest"/*.pem
}

reloadServices() {
    local cert_id="$1"

    /usr/local/bin/synology-letsencrypt-reload-services.sh "$cert_id"
}
