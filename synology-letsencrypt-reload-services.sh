#!/bin/bash
set -euo pipefail

# Reload services assigned to the certificate with the key `cert_id` in the INFO file.

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

CERT_ID="${1:?usage: $0 <cert_id>}"

ARCHIVE_PATH="/usr/syno/etc/certificate/_archive"
INFO="$ARCHIVE_PATH/INFO"

get() {
    local i="$1" prop="$2"
    jq -r --arg cert_id "$CERT_ID" --arg i "$i" --arg prop "$prop" '.[$cert_id].services[$i|tonumber][$prop]' "$INFO"
}

find_exec_path() {
    local subscriber="$1"
    local base script

    # search DSM6 and DSM7 paths
    for base in /usr/libexec/certificate.d /usr/local/libexec/certificate.d \
                /usr/syno/share/certificate.d /usr/local/share/certificate.d
    do
        script="$base/$subscriber"
        if [[ -x "$script" ]]; then
            printf '%s' "$script"
            break
        fi
    done
    return 0  # empty output means "not found"; caller handles it
}

find_cert_path() {
    local subscriber="$1" service="$2"
    local base dir

    for base in /usr/local/etc/certificate /usr/syno/etc/certificate; do
        dir="$base/$subscriber/$service"
        if [[ -e "$dir" ]]; then
            printf '%s' "$dir"
            break
        fi
    done
    return 0
}

reload_services() {
    local services_length i subscriber service cert_path exec_path profile_exec_script profile_exec_path

    services_length=$(jq -r --arg cert_id "$CERT_ID" '.[$cert_id].services|length' "$INFO")

    for (( i = 0; i < services_length; i++ )); do

        subscriber=$(get "$i" subscriber)
        service=$(get "$i" service)

        cert_path="$(find_cert_path "$subscriber" "$service")"
        if [[ -z $cert_path ]]; then
            echo >&2 "cert_path not found in for \"$subscriber\" \"$service\""
            continue
        fi

        if diff -q "$ARCHIVE_PATH/$CERT_ID/cert.pem" "$cert_path/cert.pem" >/dev/null; then
            continue # no change
        fi

        cp "$ARCHIVE_PATH/$CERT_ID/"{cert,chain,fullchain,privkey}.pem "$cert_path/"

        exec_path="$(find_exec_path "$subscriber")"
        if [[ -x $exec_path ]]; then
            "$exec_path" "$service"
        fi

        profile_exec_script="${subscriber}.sh"
        if [[ $subscriber == "system" && $service == "default" ]]; then
            profile_exec_script="dsm.sh"
        fi
        profile_exec_path="/usr/libexec/security-profile/tls-profile/$profile_exec_script"
        if [[ -x $profile_exec_path ]]; then
            "$profile_exec_path"
        fi
    done
}

reload_services

