#!/bin/bash

{

while getopts ":a:h" opt; do
  case $opt in
    a) ARCH="$OPTARG";;
    h) echo "Usage: $0 [-a <arch>]"
       echo "  -a <arch>  Architecture of lego to install (default: $(dpkg --print-architecture))"
       exit 0
    ;;
    :) echo "Error: -${OPTARG} requires an argument.";;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

ARCH=${ARCH:-$(dpkg --print-architecture)}

permissions() {
    local mod="$1"
    local path="$2"

    sudo chown root:root "$path"
    sudo chmod "$mod" "$path"
}

install_lego() {
    local path="/usr/local/bin/lego"
    local url
    
    url="$(
        curl -sSL "https://api.github.com/repos/go-acme/lego/releases/latest" \
        | jq --unbuffered -r --arg arch "$ARCH" '.assets[].browser_download_url | select(.|endswith("linux_\($arch).tar.gz"))'
    )"

    if [[ -z $url ]]; then
        echo "Could not find lego download URL for architecture '$ARCH'! Try a different architecture maybe? See '$0 -h'" >&2
        exit 1
    fi

    curl -sSL "$url" \
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

# Specify DNS Provider (this example is from https://go-acme.github.io/lego/dns/simply/)
DNS_PROVIDER="simply"
export SIMPLY_ACCOUNT_NAME=XXXXXXX
export SIMPLY_API_KEY=XXXXXXXXXX
export SIMPLY_PROPAGATION_TIMEOUT=1800
export SIMPLY_POLLING_INTERVAL=30

# Should you need it; additional options can be passed directly to lego
#LEGO_OPTIONS=(--key-type "rsa4096" --server "https://acme-staging-v02.api.letsencrypt.org/directory")
EOF
    fi

    permissions 600 "$env"
    printf "installed: %s\n" "$env"
    
    cat << EOF
    All done!

Check $env and edit as needed.
EOF
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
