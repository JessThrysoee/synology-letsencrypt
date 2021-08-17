#!/bin/bash

{

permissions() {
    local mod="$1"
    local path="$2"

    sudo chown root:root "$path"
    sudo chmod "$mod" "$path"
}

install_lego() {
    local path="/usr/local/bin/lego"

    curl -sSL "https://api.github.com/repos/go-acme/lego/releases/latest" \
        | jq --unbuffered -r --arg arch "$(dpkg --print-architecture)" '.assets[].browser_download_url | select(.|endswith("linux_\($arch).tar.gz"))' \
        | xargs curl -sSL \
        | sudo tar -zx -C "${path%/*}" -- "${path##*/}"

    permissions 755 "$path"
    printf "installed: %s\n" "$path"
}

install_script() {
    local name="$1"
    local path="/usr/local/bin/$name"

    sudo curl -sSL -o "$path" "https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/$name"

    permissions 755 "$path"
    printf "installed: %s\n" "$path"
}


install_configuration() {
    local dir="/usr/local/etc/synology-letsencrypt"
    local env="$dir/env"

    sudo mkdir -p "$dir"
    permissions 700 "$dir"

    if [[ ! -s $env ]]; then
        sudo tee "$env" > /dev/null <<EOF
DOMAINS=(--domains "example.com" --domains "*.example.com")
EMAIL="user@example.com"

## Specify DNS Provider (this example is from https://go-acme.github.io/lego/dns/simply/)
#DNS_PROVIDER="simply"
#export SIMPLY_ACCOUNT_NAME=XXXXXXX
#export SIMPLY_API_KEY=XXXXXXXXXX
#export SIMPLY_PROPAGATION_TIMEOUT=1800
#export SIMPLY_POLLING_INTERVAL=30
EOF
    fi

    permissions 600 "$env"
    printf "installed: %s\n" "$env"
}


install() {
    install_lego
    install_script "synology-letsencrypt.sh"
    install_script "synology-letsencrypt-reload-services.sh"
    install_script "synology-letsencrypt-make-cert-id.sh"
    install_configuration
}

install
}
