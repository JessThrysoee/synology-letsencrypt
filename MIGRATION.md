# Migrating to the lego config file

This release moves your configuration out of the old `env` file into lego's
[config file](https://go-acme.github.io/lego/references/ref-file/) format:
`lego.yml` for settings and `lego.env` for DNS provider credentials.

Do this once, in order:

1. **Update.** Run the [install script](install.sh). It updates `lego` and this
   project's scripts, and creates a template `lego.yml` and `lego.env` (your old
   `env` is left untouched).

2. **Migrate storage, only if you are still on `lego` v4** (you have never run
   `lego migrate`). This rewrites your account and certificate files to the v5
   layout in place; it does not rename or re-issue anything:

       /usr/local/bin/lego migrate --path /usr/local/etc/synology-letsencrypt/

   If you are already on v5, skip this step.

3. **Move your settings into the new files:**

   - Copy your DNS provider credentials from the old `env` into `lego.env` (drop
     the `export` keyword; keep the provider variables, including any
     propagation/polling settings).
   - In `lego.yml`, set your DNS provider under `challenges:` and your domain(s)
     under `certificates:`. **Name each certificate after your existing one** so
     lego keeps renewing the same certificate and your DSM service assignments
     stay in place. List your existing names with:

         lego certificates list --path /usr/local/etc/synology-letsencrypt/ --json | jq -r '.[] | .name'

     See [Configuration](README.md#configuration) for the full `lego.yml` example.

4. **Verify.** Run `/usr/local/bin/synology-letsencrypt.sh`.

5. **Clean up.** Delete the old `env` and `hook` files.

The `DOMAINS`, `EMAIL`, `DNS_PROVIDER`, `LEGO_OPTIONS`, and `DEPLOY_HOOK`
variables no longer exist; their equivalents now live in `lego.yml` (domains,
provider, extra options, and `hooks.deploy`) and `lego.env` (credentials).

More information: the [v5 blog post](https://ldez.github.io/blog/2026/05/11/lego-v5/)
and the [lego migration guide](https://go-acme.github.io/lego/migration/).
