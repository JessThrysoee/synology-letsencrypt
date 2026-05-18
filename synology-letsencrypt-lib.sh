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


# implement `lego`SanitizedName [ref.: https://github.com/go-acme/lego/blob/f9f9645cf7be7d399c025ec596484263eb9f963a/cmd/internal/storage/storage_certificates.go#L67]
sanitizedName() {
    if command -v python3 &>/dev/null; then
        python3 -c '
import sys

name = sys.argv[1]

try:
    safe = name.replace(":", "-").replace("*", "_").encode("idna").decode("ascii")
except Exception as e:
    sys.stderr.write("Could not sanitize the name: %s\n" % e)
    sys.exit(1)

out = "".join(ch for ch in safe if ch.isalnum() or ch in "-_.@")
sys.stdout.write(out)
' "$1" || return $?
    else
        python2 -c '
import sys

name = sys.argv[1]

try:
    safe = name.decode("utf-8").replace(":", "-").replace("*", "_").encode("idna")
except Exception as e:
    sys.stderr.write("Could not sanitize the name: %s\n" % e)
    sys.exit(1)

out = "".join(ch for ch in safe if ch.isalnum() or ch in "-_.@")
sys.stdout.write(out)
' "$1" || return $?
    fi
}

