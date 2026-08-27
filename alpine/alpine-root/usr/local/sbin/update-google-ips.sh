#!/usr/bin/env bash

# https://cloud.google.com/compute/docs/faq#find_ip_range

PATH_PREFIX="/var/tmp/google"
PREFIX="https://raw.githubusercontent.com/lord-alfred/ipranges/main"

sum() {
  cat ${PATH_PREFIX}*ipv{4,6}.txt 2>>/dev/null | sha256sum
}

parse() {
  version="$1"
  jq --raw-output --monochrome-output ".prefixes[] | .ipv${version}Prefix" | grep -v 'null'
}

write() {
  version="$1"
  cidr="$2"
  target="$3"
  output="${PATH_PREFIX}-${target}-ipv${version}.txt"
  temp="${output}.tmp"
  grepcidr -e "${cidr}" | sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 1 ] && mv "${temp}" "${output}"
}

get() {
  url="$1"
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "${url}"
  echo
}

download() {
  target="$1"
  ips=$(get "https://www.gstatic.com/ipranges/${target}.json")
  parse 4 <<< "${ips}" | write 4 '0.0.0.0/0' "${target}"
  parse 6 <<< "${ips}" | write 6 '::/0' "${target}"
}

download_googlebot() {
  get "${PREFIX}/googlebot/ipv4_merged.txt" | write 4 '0.0.0.0/0' 'googlebot'
  get "${PREFIX}/googlebot/ipv6_merged.txt" | write 6 '::/0' 'googlebot'
}

before=$(sum)
download 'cloud'
download 'goog'
download_googlebot
after=$(sum)
[ "${before}" != "${after}" ] && exit 0 || exit 1
