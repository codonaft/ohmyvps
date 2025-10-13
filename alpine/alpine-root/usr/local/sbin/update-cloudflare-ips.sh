#!/usr/bin/env bash

# https://www.cloudflare.com/ips/

source /etc/profile.d/99local.sh

PATH_PREFIX="/var/tmp/cloudflare-ipv"

load() {
  cat ${PATH_PREFIX}{4,6}.txt 2>>/dev/null
}

sum() {
  load | sha256sum
}

download() {
  version="$1"
  cidr="$2"
  output="${PATH_PREFIX}${version}.txt"
  temp="${output}.tmp"
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "https://www.cloudflare.com/ips-v${version}" | grepcidr -e "${cidr}" | sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 1 ] && mv "${temp}" "${output}"
}

before=$(sum)
download 4 '0.0.0.0/0'
download 6 '::/0'
after=$(sum)

[ "${before}" != "${after}" ] && {
  temp="${NGINX_CLOUDFLARE_CONF}.tmp"
  load | sed 's!^!set_real_ip_from !;s!$!;!' > "${temp}"
  mv "${temp}" "${NGINX_CLOUDFLARE_CONF}"
} || exit 1
