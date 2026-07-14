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
> Already have `synology-letsencrypt` installed? Configuration now lives in
> lego's config file. See [MIGRATION.md](MIGRATION.md) before updating.

## Configuration

Configuration lives in two files, both created by the install script under `/usr/local/etc/synology-letsencrypt/`:

- `lego.yml`: your domains, DNS provider, and other non-secret settings, in lego's [config file](https://go-acme.github.io/lego/references/ref-file/) format.
- `lego.env`: your DNS provider credentials, referenced from `lego.yml` via `envFile`.

Edit `lego.yml` with your domain(s) and DNS provider. The example uses [simply.com](https://go-acme.github.io/lego/dns/simply/), but you can use whichever [DNS provider](https://go-acme.github.io/lego/dns/) you like:

```yaml
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
  example.com:  # name for this certificate (lego names its cert files after it); use your main domain
    challenge: simply
    domains:
      - example.com
      - "*.example.com"

hooks:
  deploy:
    command: /usr/local/bin/synology-letsencrypt-deploy-hook.sh
```

Then put your DNS provider credentials in `lego.env`:

```sh
# simply.com -- https://go-acme.github.io/lego/dns/simply/
SIMPLY_ACCOUNT_NAME=XXXXXXXX
SIMPLY_API_KEY=XXXXXXXXXXXXXXXX
```

You should now be able to run `/usr/local/bin/synology-letsencrypt.sh`.

To schedule a daily task, log in to Synology DSM and add a user-defined script:

    Synology DSM -> Control Panel -> Task Scheduler
       Create -> Scheduled Task -> User-defined script
          General -> User = root
          Task Settings -> User-defined script = /bin/bash /usr/local/bin/synology-letsencrypt.sh

To secure services with the certificate, see the [Configure Certificates](https://kb.synology.com/en-global/DSM/help/DSM/AdminCenter/connection_certificate?version=7#b_64) documentation.

### Multiple Certificates

To maintain more than one certificate on your Synology, add another entry under `certificates:` in the same `lego.yml`. Each entry has its own name, challenge, and domains:

```yaml
certificates:
  example.com:
    challenge: simply
    domains:
      - example.com
      - "*.example.com"

  other-example.com:
    challenge: simply
    domains:
      - other-example.com
```

If a certificate uses a different DNS provider, add another entry under `challenges:` and point the certificate at it.

Every certificate in this file is deployed to this Synology, because the `hooks.deploy` command is a **global** lego setting that runs once for each certificate that was issued or renewed. Therefore, only put certificates you actually want installed on this Synology here.

If you also use `lego` to obtain certificates for *other* purposes (a different host, a service that is not on this Synology), keep those in a **separate** `lego.yml` outside this project, with its own (or no) deploy hook. That keeps them from being deployed into this Synology's certificate store.

### Customizing the deploy hook

After each successful issuance or renewal, `lego` runs the deploy hook configured
as `hooks.deploy.command` in `lego.yml`, which by default is
`/usr/local/bin/synology-letsencrypt-deploy-hook.sh`. It generates the PEM files
Synology expects and reloads the affected services.

To run your own hook instead, change that command to point at your script:

```yaml
hooks:
  deploy:
    command: /usr/local/etc/synology-letsencrypt/my-deploy-hook.sh
```

## Uninstall

To **uninstall** `synology-letsencrypt`, run the [uninstall script](uninstall.sh). You can either download and run the script manually, or use the following curl command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/uninstall.sh | bash
```

> [!WARNING]
> This removes the `lego` binary, the project scripts, and the entire
> `/usr/local/etc/synology-letsencrypt/` directory, including your configuration
> (`lego.yml`, `lego.env`) and lego's storage (the ACME account and every issued
> certificate). It does not remove certificates already installed in DSM; the
> script reminds you to delete those manually under Control Panel -> Security ->
> Certificate.

## Consider the [acme-dns](https://github.com/joohoi/acme-dns) project

...if your DNS provider is not _directly_ supported by `lego`, or if you want to avoid storing your DNS provider's API keys on your Synology device. `lego` supports [acme-dns](https://go-acme.github.io/lego/dns/acme-dns/).
