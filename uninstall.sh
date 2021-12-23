#!/bin/bash

{

uninstall_script() {
    local name="$1"
    local path="/usr/local/bin/$name"

    sudo rm "$path"

    printf "uninstalled: %s\n" "$path"
}

uninstall_configuration() {
    local path="/usr/local/etc/synology-letsencrypt"

    sudo rm -r "$path"

    printf "uninstalled configuration: %s\n" "$path"
}

uninstall_cert_message() {
    echo ""
    echo "Remove any Let's Encrypt certificates from:"
    echo "   Synology DSM -> Control Panel -> Security -> Certificate"
    echo ""
}

uninstall() {
    uninstall_script "lego"
    uninstall_script "synology-letsencrypt.sh"
    uninstall_script "synology-letsencrypt-reload-services.sh"
    uninstall_script "synology-letsencrypt-make-cert-id.sh"
    uninstall_configuration
    uninstall_cert_message
}

uninstall
}
