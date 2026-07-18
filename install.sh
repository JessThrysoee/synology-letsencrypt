#!/bin/bash

{
set -euo pipefail

arch_map() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)       echo "amd64" ;;
        aarch64)      echo "arm64" ;;
        armv7l)       echo "armv7" ;;
        i686|i386)    echo "386" ;;
        *)            return 1 ;;
    esac
}

while getopts ":a:b:h" opt; do
  case $opt in
    a) ARCH="$OPTARG";;
    b) BRANCH="$OPTARG";;
    h) echo "Usage: $0 [-a <arch>]"
       echo "  -a <arch>  Architecture of lego to install (auto-detect: $(arch_map || echo "unsupported"))"
       exit 0
    ;;
    :) echo "Error: -${OPTARG} requires an argument.";;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ -z ${ARCH:-} ]]; then
    ARCH=$(arch_map) || {
        echo "Error: Unsupported architecture '$(uname -m)'. Use -a to specify manually." >&2
        exit 1
    }
fi

BRANCH="${BRANCH:-master}"

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
        curl -fsSL "https://api.github.com/repos/go-acme/lego/releases/latest" \
        | jq --unbuffered -r --arg arch "$ARCH" '.assets[].browser_download_url | select(.|endswith("linux_\($arch).tar.gz"))'
    )"

    if [[ -z $url ]]; then
        echo "Could not find lego download URL for architecture '$ARCH'! Try a different architecture maybe? See '$0 -h'" >&2
        exit 1
    fi

    curl -fsSL "$url" \
        | sudo tar -zx -C "${path%/*}" -- "${path##*/}"

    permissions 755 "$path"
    printf "installed: %s\n" "$path"
}

install_script() {
    local name="$1"
    local path="/usr/local/bin/$name"

    sudo curl -fsSL -o "$path" "https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/$BRANCH/$name"

    permissions 755 "$path"
    printf "installed: %s\n" "$path"
}


install_configuration() {
    local dir="/usr/local/etc/synology-letsencrypt"
    local config="$dir/lego.yml"
    local creds="$dir/lego.env"

    sudo mkdir -p "$dir"
    permissions 700 "$dir"

    if [[ ! -s $config ]]; then
        sudo tee "$config" > /dev/null <<EOF
# Reference: https://go-acme.github.io/lego/references/ref-file/
# Run via:   synology-letsencrypt.sh   (wraps: lego --config <this file>)
#
# Only certificates meant for THIS Synology belong here. The deploy hook below
# is global -- it runs for every certificate in this file. Keep certificates for
# other hosts or uses in a SEPARATE lego.yml outside this project.

storage: /usr/local/etc/synology-letsencrypt

accounts:
  default:
    acceptsTermsOfService: true
    #server: letsencrypt-staging

challenges:
  # DNS-01 via simply.com -- https://go-acme.github.io/lego/dns/simply/
  simply:
    dns:
      provider: simply
      envFile: /usr/local/etc/synology-letsencrypt/lego.env

certificates:
  "example.com":  # name for this certificate (lego names its cert files after it); use your main domain
    challenge: simply
    domains:
      - example.com
      - "*.example.com"

hooks:
  deploy:
    command: /usr/local/bin/synology-letsencrypt-deploy-hook.sh
EOF
    fi

    permissions 600 "$config"
    printf "installed: %s\n" "$config"

    if [[ ! -s $creds ]]; then
        sudo tee "$creds" > /dev/null <<EOF
# DNS provider credentials, referenced by envFile in lego.yml.

# simply.com -- https://go-acme.github.io/lego/dns/simply/
SIMPLY_ACCOUNT_NAME=XXXXXXXX
SIMPLY_API_KEY=XXXXXXXXXXXXXXXX
EOF
    fi

    permissions 600 "$creds"
    printf "installed: %s\n" "$creds"

    cat << EOF
    All done!

Check $config and $creds and edit as needed.
EOF
}

ensure_usr_local_bin() {
    local dir="/usr/local/bin"

    if [[ ! -d $dir ]]; then
        sudo mkdir -p "$dir"
        permissions 755 "$dir"
    fi
}

uninstall_deprecated_script() {
    local path="/usr/local/bin/$1"

    if [[ -f "$path" ]]; then
        sudo rm "$path"

        printf "uninstalled: %s\n" "$path"
    fi
}

install() {
    ensure_usr_local_bin
    install_lego
    install_script "synology-letsencrypt.sh"
    install_script "synology-letsencrypt-deploy-hook.sh"
    install_script "synology-letsencrypt-reload-services.sh"
    install_script "synology-letsencrypt-lib.sh"
    uninstall_deprecated_script "synology-letsencrypt-make-cert-id.sh"
    install_configuration
}

install

}
