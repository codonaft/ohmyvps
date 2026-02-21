#!/usr/bin/env bash

source /etc/profile.d/99local.sh

follow () {
  tail -F "${SYSLOG}" /var/log/nginx/{access,error}.log
}

[[ $(wc -l "${LOCAL_BANLIST}" | awk '{print $1}') -gt 0 ]] && {
  ignored_ips=$(echo -n '(' ; paste -sd '|' "${LOCAL_BANLIST}" | sed 's!\.!\\.!g' | tr '\n' ')')
  follow | grep --invert-match --extended-regexp "${ignored_ips}"
} || follow
