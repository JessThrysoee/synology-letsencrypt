#!/bin/bash

{

install_lego() {
  local path="/usr/local/bin/lego"

  curl -sSL "https://api.github.com/repos/go-acme/lego/releases/latest" \
    | jq --unbuffered -r --arg arch "$(dpkg --print-architecture)" '.assets[].browser_download_url | select(.|endswith("linux_\($arch).tar.gz"))' \
    | xargs curl -sSL \
    | sudo tar -zx -C "${path%/*}" -- "${path##*/}"

  chown root:root "$path"
  chmod 755 "$path"

  printf "installed: %s\n" "$path"
}

install_reload_services() {
  local path="/usr/local/bin/synology-letsencrypt-reload-services.sh"

  sudo curl -sSL -o "$path" "https://raw.githubusercontent.com/JessThrysoee/synology-letsencrypt/master/synology-letsencrypt-reload-services.sh"

  chown root:root "$path"
  chmod 755 "$path"

  printf "installed: %s\n" "$path"
}


install() {
  install_lego
  install_reload_services
}

}
