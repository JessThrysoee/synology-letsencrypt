#!/bin/bash -e

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

export LEGO_PATH="/usr/local/etc/synology-letsencrypt"
source "$LEGO_PATH/env"

cert_path="$LEGO_PATH/certificates"
cert_domain="${DOMAINS[1]#\*.}"
hook_path="$LEGO_PATH/hook"


## cert_id
cert_id_path="$cert_path/$cert_domain.cert_id"
if [[ ! -s $cert_id_path ]]; then
    mkdir -p "$cert_path"
    /usr/local/bin/synology-letsencrypt-make-cert-id.sh > "$cert_id_path"
fi
source "$cert_id_path"


## install hook
archive_path="/usr/syno/etc/certificate/_archive/$cert_id"

cat > "$hook_path" <<EOF
#!/bin/bash

cp  $cert_path/$cert_domain.crt "$archive_path/cert.pem"
cp  $cert_path/$cert_domain.issuer.crt "$archive_path/chain.pem"
cat $cert_path/$cert_domain.crt $cert_path/$cert_domain.issuer.crt > $archive_path/fullchain.pem
cp  $cert_path/$cert_domain.key $archive_path/privkey.pem

/usr/local/bin/synology-letsencrypt-reload-services.sh "$cert_id"
EOF

chmod 700 "$hook_path"


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


