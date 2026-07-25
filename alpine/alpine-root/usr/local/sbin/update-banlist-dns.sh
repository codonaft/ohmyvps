#!/usr/bin/env bash

source /etc/profile.d/99local.sh

new="${DNS_BANLIST}.new"

wget -qO - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts | \
  awk '/Title: Hosts contributed by Steven Black/{p=1; fflush()} p' | \
  grep --line-buffered --invert-match --extended-regexp '(^0.0.0.0 0.0.0.0$|^#)' | \
  grep --line-buffered '^0\.0\.0\.0 ' | \
  sed --unbuffered 's!^0\.0\.0\.0 !127.1.1.1 !' > "${new}"

[ -s "${new}" ] && [ $(stat -c "%s" "${new}") -gt 1 ] && mv "${new}" "${DNS_BANLIST}" || exit 1
