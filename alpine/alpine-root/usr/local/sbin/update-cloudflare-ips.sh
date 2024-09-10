#!/usr/bin/env bash

sum () {
  cat /tmp/cloudflare-ipv{4,6}.txt 2>>/dev/null | sha256sum
}

download () {
  version="$1"
  cidr="$2"
  output="/var/tmp/cloudflare-ipv${version}.txt"
  temp="${output}.tmp"
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "https://www.cloudflare.com/ips-v${version}" | grepcidr -e "${cidr}" | sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 0 ] && mv "${temp}" "${output}"
}

before=$(sum)
download 4 '0.0.0.0/0'
download 6 '::/0'
after=$(sum)

[ "${before}" != "${after}" ]
exit $?
