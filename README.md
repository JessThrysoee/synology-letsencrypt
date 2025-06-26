# synology-letsencrypt

Create and maintain a [Let's Encrypt](https://letsencrypt.org/) certificate on a Synology NAS.

Uses [lego](https://go-acme.github.io/lego/) and the [ACME DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) for any of the supported [DNS Providers](https://go-acme.github.io/lego/dns/).

## Install & Update Script

To **install** or **update** synology-letsencrypt, run the [install script](install.sh). To do that, either download and run the script manually, or use the following cURL command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/install.sh | bash
```

The script has to be run as root. To run it as root, you can SSH into your NAS with an admin user and then issue `sudo -i` to become root (the password is the same as the admin user's).

## Configuration

Update `/usr/local/etc/synology-letsencrypt/env` with domain(s), email, and DNS API-key:

```sh
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
#LEGO_RUN_OPTIONS=()
#LEGO_RENEW_OPTIONS=(--ari-disable)
```

Note: If you are generating a wildcard certificate, you must include the base domain next to the wildcard domain. For example, if you want to create a certificate for `*.example.com`, you must also include `example.com` in the `DOMAINS` value.

Now you should be able to run `/usr/local/bin/synology-letsencrypt.sh`.

To schedule a daily task, log into the Synology DSM and add a user-defined script:

    Synology DSM -> Control Panel -> Task Scheduler
       Create -> Scheduled Task -> User-defined script
          General -> User = root
          Task Settings -> User-defined script = /bin/bash /usr/local/bin/synology-letsencrypt.sh

To secure services with the certificate, se the [Configure Certificates](https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/connection_certificate?version=7#b_64) documentation.

### Multiple Certificates

If you need to generate more than one certificate, you can parameterize synology-letsencrypt.sh with the path of a certificate configuration:

```shellsession
$ /usr/local/bin/synology-letsencrypt.sh -p /usr/local/bin/synology-letsencrypt/example.com
$ /usr/local/bin/synology-letsencrypt.sh -p /usr/local/bin/synology-letsencrypt/other-example.com
```

This creates an entire configuration in
`/usr/local/etc/synology-letsencrypt/example.com/env` and
`/usr/local/etc/synology-letsencrypt/other-example.com/env` respectively, which
you can tune according to your needs. That extends to modifying the `hook` in
each one to match your needs.

You might want this if you require more than one certificate on the Synology, or
if you want to generate a certificate for another host on your Synology.

### Customizing the hook script

By default, `synology-letsencrypt.sh` will overwrite any changes you make to the
hook script to preserve the core functionality of this client. If you have customized your script, you can preserve its changes by adding the `-c` parameter to your invocation:

```shellsession
$ /usr/local/bin/synology-letsencrypt.sh -c
```

## Uninstall

To **uninstall** synology-letsencrypt, run the [uninstall script](uninstall.sh). To do that, either download and run the script manually, or use the following cURL command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/uninstall.sh | bash
```
