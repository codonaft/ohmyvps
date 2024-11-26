#!/usr/bin/env bash

PATH_PREFIX="/var/tmp/cloudflare-ipv"
NGINX_CONF="/etc/nginx/cloudflare.conf"

load () {
  cat ${PATH_PREFIX}{4,6}.txt 2>>/dev/null
}

sum () {
  load | sha256sum
}

download () {
  version="$1"
  cidr="$2"
  output="${PATH_PREFIX}${version}.txt"
  temp="${output}.tmp"
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "https://www.cloudflare.com/ips-v${version}" | grepcidr -e "${cidr}" | sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 0 ] && mv "${temp}" "${output}"
}

before=$(sum)
download 4 '0.0.0.0/0'
download 6 '::/0'
after=$(sum)

[ "${before}" != "${after}" ] && {
  temp="${NGINX_CONF}.tmp"
  load | sed 's!^!set_real_ip_from !;s!$!;!' > "${temp}"
  mv "${temp}" "${NGINX_CONF}"
} || exit 1
