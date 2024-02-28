#!/bin/bash

# Reload services assigned to the certificate with the key `cert_id` in the INFO file.
# Inspired by https://github.com/bartowl/synology-stuff/blob/master/reload-certs.sh

CERT_ID="$1"

ARCHIVE_PATH="/usr/syno/etc/certificate/_archive"
INFO="$ARCHIVE_PATH/INFO"


get() {
    local i="$1"
    local prop="$2"
    jq -r --arg cert_id "$CERT_ID" --arg i "$i" --arg prop "$prop" '.[$cert_id].services[$i|tonumber][$prop]' "$INFO"
}


reload_services() {
    local tls_profile_path="/usr/libexec/security-profile/tls-profile"

    services_length=$(jq -r --arg cert_id "$CERT_ID" '.[$cert_id].services|length' "$INFO")

    for (( i = 0; i < services_length; i++ )); do

        isPkg=$(get "$i" isPkg)
        subscriber=$(get "$i" subscriber)
        service=$(get "$i" service)

        if [[ $isPkg == true ]]; then
            exec_path="/usr/local/libexec/certificate.d/$subscriber"
            cert_path="/usr/local/etc/certificate/$subscriber/$service"
        else
            exec_path="/usr/libexec/certificate.d/$subscriber"
            cert_path="/usr/syno/etc/certificate/$subscriber/$service"

            if [[ -x $tls_profile_path/${subscriber}.sh ]]; then
                exec_path="$tls_profile_path/${subscriber}.sh"
            fi

            if [[ $subscriber == "system" && $service == "default" && -x $tls_profile_path/dsm.sh ]]; then
                exec_path="$tls_profile_path/dsm.sh"
            fi
        fi

        if ! diff -q "$ARCHIVE_PATH/$CERT_ID/cert.pem" "$cert_path/cert.pem" >/dev/null; then
            cp "$ARCHIVE_PATH/$CERT_ID/"{cert,chain,fullchain,privkey}.pem "$cert_path/"

            if [[ -x $exec_path ]]; then
                if [[ $subscriber == "system" && $service == "default" ]]; then "$exec_path" else "$exec_path" "$service"; fi
            fi

        fi

    done
}


reload_nginx() {
    /usr/syno/bin/synow3tool --gen-all

    if [[ -x /usr/syno/bin/synosystemctl ]]; then
        if /usr/syno/bin/synow3tool --nginx=is-running > /dev/null 2>&1; then
            /usr/syno/bin/synosystemctl reload --no-block nginx
        fi
    elif [[ -x /usr/syno/sbin/synoservice ]]; then
        if /usr/syno/sbin/synoservice --status nginx > /dev/null 2>&1; then
            /usr/syno/bin/synow3tool --gen-nginx-tmp && /usr/syno/sbin/synoservice --reload nginx
        fi
    else
        echo "synosystemctl or synoservice not found" >&2
    fi
}


reload_services
reload_nginx


