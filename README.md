# synology-letsencrypt

Create and maintain a [Let's Encrypt](https://letsencrypt.org/) certificate on a Synology NAS.

Uses [lego](https://go-acme.github.io/lego/) and the [ACME DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) for any of the supported [DNS Providers](https://go-acme.github.io/lego/dns/).

## Install & Update Script

To **install** or **update** synology-letsencrypt, run the [install script](install.sh). To do that, either download and run the script manually, or use the following cURL command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/install.sh | bash
```

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
```

Now you should be able to run `/usr/local/bin/synology-letsencrypt.sh`.

To schedule a daily task, log into the Synology DSM and add a user-defined script:

    Synology DSM -> Control Panel -> Task Scheduler
       Create -> Scheduled Task -> User-defined script
          General -> User = root
          Task Settings -> User-defined script = /usr/local/bin/synology-letsencrypt.sh

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
