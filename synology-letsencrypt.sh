#!/bin/bash -e

[[ $EUID == 0 ]] || { echo >&2 "This script must be run as root"; exit 1; }

export LEGO_PATH="$HOME/.lego"
mkdir -p "$LEGO_PATH"

env="$LEGO_PATH/env"
if [[ ! -s $env ]]; then
    echo >&2 "Missing configuration $env: See example at https://github.com/JessThrysoee/synology-letsencrypt#configuration"
else
    source "$env"
fi

cert_path="$LEGO_PATH/certificates"
cert_domain="${DOMAINS[1]#\*.}"
hook_path="$LEGO_PATH/hook"


## cert_id
cert_id_path="$cert_path/$cert_domain.cert_id"
[[ ! -s $cert_id_path ]] && /usr/local/bin/synology-letsencrypt-make-cert-id.sh > "$cert_id_path"
source $cert_id_path
echo $cert_id_path


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


