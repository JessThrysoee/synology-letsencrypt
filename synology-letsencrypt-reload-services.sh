#!/bin/bash

# Reload services assigned to the certificate with the key `cert_id` in the INFO file.
# Inspired by https://github.com/bartowl/synology-stuff/blob/master/reload-certs.sh

CERT_ID="$1"

ARCHIVE_PATH="/usr/syno/etc/certificate/_archive"
INFO="$ARCHIVE_PATH/INFO"


get() {
    local i="$1" prop="$2"
    jq -r --arg cert_id "$CERT_ID" --arg i "$i" --arg prop "$prop" '.[$cert_id].services[$i|tonumber][$prop]' "$INFO"
}

find_exec_path() {
    local subscriber="$1"

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
}

find_cert_path() {
    local subscriber="$1" service="$2"

    for base in /usr/local/etc/certificate /usr/syno/etc/certificate; do
        dir="$base/$subscriber/$service"
        if [[ -e "$dir" ]]; then
            printf '%s' "$dir"
            break
        fi
    done
}

reload_services() {
    services_length=$(jq -r --arg cert_id "$CERT_ID" '.[$cert_id].services|length' "$INFO")

    for (( i = 0; i < services_length; i++ )); do

        subscriber=$(get "$i" subscriber)
        service=$(get "$i" service)

        cert_path="$(find_cert_path "$subscriber" "$service")"

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

