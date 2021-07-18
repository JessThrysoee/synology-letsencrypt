### Install & Update Script

To **install** or **update** synology-letsencrypt, you should run the [install script](install.sh). To do that, you may either download and run the script manually, or use the following cURL command:

```sh
curl -sSL https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/install.sh | bash
```


### Configuration

An example of a configuration, `$HOME/.lego/env`.

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





