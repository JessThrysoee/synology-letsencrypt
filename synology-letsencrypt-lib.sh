#!/bin/bash -e

makeCertId() {
    local cert_id_path="$1"
    local archive_path="$2"

    local cert_id=""
    if [[ -s $cert_id_path ]]; then
        source "$cert_id_path"
    fi

    mkdir -p "$archive_path"

    if [[ -z $cert_id ]]; then
        local archive_cert_path
        archive_cert_path=$(mktemp -d "$archive_path"/XXXXXX)
        cert_id="${archive_cert_path##*/}"
        printf 'cert_id=%s' "$cert_id" > "$cert_id_path"
    fi

    mkdir -p "$archive_path/$cert_id"

    local info="$archive_path/INFO"
    if [[ -s $info ]]; then
        local has_cert_id
        has_cert_id="$(jq --arg cert_id "$cert_id" 'has($cert_id)' "$info")"

        if [[ $has_cert_id != true ]]; then
            # append
            local tmp_info
            tmp_info=$(mktemp)
            jq --arg cert_id "$cert_id" '.[$cert_id] = { desc: "", services: [] }' < "$info" > "$tmp_info" \
                && \mv "$tmp_info" "$info"
        fi
    else
        # create
        jq -n --arg cert_id "$cert_id" '{ ($cert_id) : { desc: "", services: [] } }' > "$info"
    fi
}


punycode() {
    if command -v python3 &>/dev/null; then
        python3 -c "import sys; [sys.stdout.write(l.strip().encode('idna').decode('ascii')+'\n') for l in sys.stdin]"
    else
        python2 -c "import sys; [sys.stdout.write(l.strip().decode('utf-8').encode('idna')+'\n') for l in sys.stdin]"
    fi
}


# implement `lego` sanitizedDomain [ref.: https://github.com/go-acme/lego/blob/e0a1fe55277b69a84c45927ef0c075ce062a86a0/cmd/certs_storage.go#L320]
sanitizedDomain() { printf '%s' "$1" | tr ':*' '-_' | punycode; }

