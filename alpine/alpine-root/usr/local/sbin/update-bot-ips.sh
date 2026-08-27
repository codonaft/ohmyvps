#!/usr/bin/env bash

PATH_PREFIX="/var/tmp/bots"
PREFIX="https://raw.githubusercontent.com/lord-alfred/ipranges/main"
IPV4=( amazon bing duckassistbot duckduckbot facebook microsoft openai perplexity pingdom statuscake twitter )
IPV6=( amazon facebook microsoft pingdom twitter )

path() {
  version="$1"
  target="$2"
  echo "${PATH_PREFIX}-${target}-ipv${version}.txt"
}

load() {
  for target in "${IPV4[@]}" ; do
    cat $(path 4 "${target}") 2>>/dev/null
  done

  for target in "${IPV6[@]}" ; do
    cat $(path 6 "${target}") 2>>/dev/null
  done
}

sum() {
  load | sha256sum
}

get() {
  url="$1"
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "${url}"
  echo
}

write() {
  version="$1"
  cidr="$2"
  target="$3"
  output=$(path "${version}" "${target}")
  temp="${output}.tmp"
  grepcidr -e "${cidr}" | \
    sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 1 ] && mv "${temp}" "${output}"
}

download() {
  for target in "${IPV4[@]}" ; do
    get "${PREFIX}/${target}/ipv4_merged.txt" | write 4 '0.0.0.0/0' "${target}"
  done

  for target in "${IPV6[@]}" ; do
    get "${PREFIX}/${target}/ipv6_merged.txt" | write 6 '::/0' "${target}"
  done
}

before=$(sum)
download
after=$(sum)
[ "${before}" != "${after}" ] && exit 0 || exit 1
