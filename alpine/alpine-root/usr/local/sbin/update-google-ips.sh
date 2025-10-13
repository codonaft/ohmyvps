#!/usr/bin/env bash

# https://cloud.google.com/compute/docs/faq#find_ip_range

PATH_PREFIX="/var/tmp/google"

load() {
  cat ${PATH_PREFIX}*ipv{4,6}.txt 2>>/dev/null
}

sum() {
  load | sha256sum
}

write () {
  version="$1"
  cidr="$2"
  target="$3"
  output="${PATH_PREFIX}-${target}-ipv${version}.txt"
  temp="${output}.tmp"
  cat | \
    jq --raw-output --monochrome-output ".prefixes[] | .ipv${version}Prefix" | \
    grep -v 'null' | \
    grepcidr -e "${cidr}" | \
    sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 1 ] && mv "${temp}" "${output}"
}

download () {
  target="$1"
  ips=$(sudo -u nobody wget --timeout=30 --tries=10 -qO - "https://www.gstatic.com/ipranges/${target}.json")
  write 4 '0.0.0.0/0' "${target}" <<< "${ips}"
  write 6 '::/0' "${target}" <<< "${ips}"
}

before=$(sum)
download 'cloud'
download 'goog'
after=$(sum)
[ "${before}" != "${after}" ] && exit 0 || exit 1
