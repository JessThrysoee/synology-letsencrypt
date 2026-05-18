# synology-letsencrypt

Create and manage a [Let's Encrypt](https://letsencrypt.org/) certificate on a Synology NAS.

This project uses [lego](https://go-acme.github.io/lego/) and the [ACME DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) with any supported [DNS provider](https://go-acme.github.io/lego/dns/).


## Install & Update Script

To **install** or **update** `synology-letsencrypt`, run the [install script](install.sh). You can either download and run the script manually, or use the following curl command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/install.sh | bash
```

The script must be run as root. You can SSH into your NAS as an admin user and then run `sudo -i` to become root (using the same password as the admin user).

> [!IMPORTANT]
> Migration from `lego` v4 to v5

If you are updating from a version of `lego` earlier than v5, note that v5 introduces breaking changes to the CLI, directory structure, and JSON file format.

After running the [install script](install.sh) to update `lego` and this repository's scripts to the latest versions, run the new v5 command `lego migrate` before running any other commands. For example:

    /usr/local/bin/lego migrate --path /usr/local/etc/synology-letsencrypt/

More information is available in the [v5 blog post](https://ldez.github.io/blog/2026/05/11/lego-v5/).

Also note that the optional environment variables `LEGO_RUN_OPTIONS` and `LEGO_RENEW_OPTIONS` in your `env` file have been replaced with a single optional variable, `LEGO_OPTIONS`.

## Configuration

Update `/usr/local/etc/synology-letsencrypt/env` with your domain(s), email address, and DNS API key:

```sh
DOMAINS=(--domains "example.com" --domains "*.example.com")
EMAIL="user@example.com"

# Specify the DNS provider (this example is from https://go-acme.github.io/lego/dns/simply/)
DNS_PROVIDER="simply"
export SIMPLY_ACCOUNT_NAME=XXXXXXX
export SIMPLY_API_KEY=XXXXXXXXXX
export SIMPLY_PROPAGATION_TIMEOUT=1800
export SIMPLY_POLLING_INTERVAL=30

# Should you need it; additional options can be passed directly to lego
#LEGO_OPTIONS=(--key-type "RSA4096" --ari-disable --server "letsencrypt-staging")
```

You should now be able to run `/usr/local/bin/synology-letsencrypt.sh`.

To schedule a daily task, log in to Synology DSM and add a user-defined script:

    Synology DSM -> Control Panel -> Task Scheduler
       Create -> Scheduled Task -> User-defined script
          General -> User = root
          Task Settings -> User-defined script = /bin/bash /usr/local/bin/synology-letsencrypt.sh

To secure services with the certificate, see the [Configure Certificates](https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/connection_certificate?version=7#b_64) documentation.

### Multiple Certificates

If you need to generate multiple certificates, you can run `synology-letsencrypt.sh` with the path to a certificate-specific configuration:


```shellsession
$ /usr/local/bin/synology-letsencrypt.sh -p /usr/local/etc/synology-letsencrypt/example.com
$ /usr/local/bin/synology-letsencrypt.sh -p /usr/local/etc/synology-letsencrypt/other-example.com
```

This creates a separate configuration in
`/usr/local/etc/synology-letsencrypt/example.com/env` and
`/usr/local/etc/synology-letsencrypt/other-example.com/env`, respectively. 
You can then customize each one as needed, including the `hook` file in each configuration.

This is useful if you need more than one certificate on your Synology or want to generate a certificate for another host managed by the Synology.

### Customizing the hook script

By default, `synology-letsencrypt.sh` overwrites any changes you make to the hook script to preserve core functionality.
If you have customized the hook script, you can preserve your changes by adding the `-c` option when running the command:

```shellsession
$ /usr/local/bin/synology-letsencrypt.sh -c
```

## Uninstall

To **uninstall** `synology-letsencrypt`, run the [uninstall script](uninstall.sh). You can either download and run the script manually, or use the following curl command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/uninstall.sh | bash
```

## Consider the [acme-dns](https://github.com/joohoi/acme-dns) project

...if your DNS provider is not _directly_ supported by `lego`, or if you want to avoid storing your DNS provider's API keys on your Synology device. `lego` supports [acme-dns](https://go-acme.github.io/lego/dns/acme-dns/).
