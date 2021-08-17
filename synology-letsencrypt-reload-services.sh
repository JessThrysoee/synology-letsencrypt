#!/bin/bash

# Reload services assigned to the certificate with the key `cert_id` in the INFO file.
# Inspired by https://github.com/bartowl/synology-stuff/blob/master/reload-certs.sh

cert_id="$1"

archive_path="/usr/syno/etc/certificate/_archive"
INFO="$archive_path/INFO"

get() { jq -r --arg cert_id "$cert_id" --arg i "$i" --arg prop "$1" '.[$cert_id].services[$i|tonumber][$prop]' "$INFO" ; }

services_length=$(jq -r --arg cert_id "$cert_id" '.[$cert_id].services|length' "$INFO")

for (( i = 0; i < services_length; i++ )); do

    isPkg=$(get isPkg)
    subscriber=$(get subscriber)
    service=$(get service)

    if [[ $isPkg == true ]]; then
        exec_path="/usr/local/libexec/certificate.d/$subscriber"
        cert_path="/usr/local/etc/certificate/$subscriber/$service"
    else
        exec_path="/usr/libexec/certificate.d/$subscriber"
        cert_path="/usr/syno/etc/certificate/$subscriber/$service"
    fi

    if ! diff -q "$archive_path/$cert_id/cert.pem" "$cert_path/cert.pem" >/dev/null; then
        cp "$archive_path/$cert_id/"{cert,chain,fullchain,privkey}.pem "$cert_path/"

        if [[ -x $exec_path ]]; then
            if [[ $subscriber == "system" && $service == "default" ]]; then "$exec_path" else "$exec_path" "$service"; fi
        fi
    fi

done

