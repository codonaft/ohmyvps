#!/usr/bin/env bash

PATH_PREFIX="/var/tmp/bots"
IPRANGES_PREFIX="https://raw.githubusercontent.com/lord-alfred/ipranges/main"
ASN_PREFIX="https://raw.githubusercontent.com/ipverse/as-ip-blocks/refs/heads/master/as"
IPV4=( amazon bing duckassistbot duckduckbot facebook microsoft openai perplexity pingdom statuscake twitter )
IPV6=( amazon facebook microsoft pingdom twitter )
ASNS=( 2763 54538 64280 396421 396982 )

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
  sudo -u nobody wget --timeout=30 --tries=10 -qO - "${url}" | grep -vE '^#'
}

write() {
  version="$1"
  cidr="$2"
  target="$3"
  output=$(path "${version}" "${target}")
  temp="${output}.tmp"
  grepcidr -e "${cidr}" | sort -u > "${temp}"
  [ "$(stat --format='%s' ${temp})" -gt 1 ] && mv "${temp}" "${output}"
}

download() {
  for target in "${IPV4[@]}" ; do
    get "${IPRANGES_PREFIX}/${target}/ipv4_merged.txt" | write 4 '0.0.0.0/0' "${target}" &
  done

  for target in "${IPV6[@]}" ; do
    get "${IPRANGES_PREFIX}/${target}/ipv6_merged.txt" | write 6 '::/0' "${target}" &
  done

  for asn in "${ASNS[@]}" ; do
    get "${ASN_PREFIX}/${asn}/ipv4-aggregated.txt" | write 4 '0.0.0.0/0' "as${asn}" &
    get "${ASN_PREFIX}/${asn}/ipv6-aggregated.txt" | write 6 '::/0' "as${asn}" &
  done

  wait
}

before=$(sum)
download
after=$(sum)
[ "${before}" != "${after}" ] && exit 0 || exit 1
