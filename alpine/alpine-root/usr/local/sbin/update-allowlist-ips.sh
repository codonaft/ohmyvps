#!/usr/bin/env bash

source /etc/profile.d/99local.sh

temp="${NGINX_ALLOWLIST_CONF}.tmp"
cat "${SSH_ALLOWLIST}" | grepcidr -e '0.0.0.0/0' | sort -u | sed 's!^!allow !;s!$!;!' > "${temp}"
cat "${SSH_ALLOWLIST}" | grepcidr -e '::/0' | sort -u | sed 's!^!allow !;s!$!;!' >> "${temp}"
echo 'deny all;' >> "${temp}"

[ -f "${NGINX_ALLOWLIST_CONF}" ] || touch "${NGINX_ALLOWLIST_CONF}"
before=$(sha256sum < "${NGINX_ALLOWLIST_CONF}")
after=$(sha256sum < "${temp}")

[ "${before}" != "${after}" ] && mv "${temp}" "${NGINX_ALLOWLIST_CONF}" || {
  rm "${temp}"
  exit 1
}
