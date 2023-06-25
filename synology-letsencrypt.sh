#!/bin/bash -e

while getopts ":p:ch" opt; do
    case $opt in
        p) LEGO_PATH="$OPTARG" ;;
        c) CREATE_HOOK=false ;;
        h)
            echo "Usage: $0 [options]"
            echo "  -p <lego_path> The path where Lego will install your certs"
            echo "  -c Suppress [c]reation of the hook scripts, if you have your own"
            exit 0
            ;;
        :) echo "Error: -${OPTARG} requires an argument" >&2 ;;
        \?) echo "Invalid option -$OPTARG" >&2 ;;
    esac
done

LEGO_PATH=${LEGO_PATH:-/usr/local/etc/synology-letsencrypt}
CREATE_HOOK=${CREATE_HOOK:-true}

[[ $EUID == 0 ]] || {
    echo >&2 "This script must be run as root"
    exit 1
}

source "$LEGO_PATH/env"

export LEGO_PATH

cert_path="$LEGO_PATH/certificates"
cert_domain="${DOMAINS[1]#\*.}"
hook_path="$LEGO_PATH/hook"

## cert_id
cert_id_path="$cert_path/$cert_domain.cert_id"
if [[ ! -s $cert_id_path ]]; then
    mkdir -p "$cert_path"
    /usr/local/bin/synology-letsencrypt-make-cert-id.sh >"$cert_id_path"
fi
source "$cert_id_path"

## install hook
archive_path="/usr/syno/etc/certificate/_archive/$cert_id"
if [[ ! -d $archive_path ]]; then
    mkdir -p "$archive_path"
fi

if [[ ${CREATE_HOOK} == true ]]; then
    cat >"$hook_path" <<EOF
#!/bin/bash

cp  $cert_path/$cert_domain.crt "$archive_path/cert.pem"
cp  $cert_path/$cert_domain.issuer.crt "$archive_path/chain.pem"
cat $cert_path/$cert_domain.crt $cert_path/$cert_domain.issuer.crt > $archive_path/fullchain.pem
cp  $cert_path/$cert_domain.key $archive_path/privkey.pem

/usr/local/bin/synology-letsencrypt-reload-services.sh "$cert_id"
EOF

    chmod 700 "$hook_path"
fi

## run or renew
if [[ -s $cert_path/$cert_domain.crt ]]; then
    CMD=(renew --renew-hook)
else
    CMD=(run --run-hook)
fi

# https://go-acme.github.io/lego/usage/cli/
/usr/local/bin/lego \
    --accept-tos \
    --key-type "rsa4096" \
    --email "$EMAIL" \
    --dns "$DNS_PROVIDER" \
    "${DOMAINS[@]}" \
    "${CMD[@]}" "$hook_path"
