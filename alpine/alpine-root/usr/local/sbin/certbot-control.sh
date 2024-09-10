#!/bin/bash

set -euo pipefail
#set -x

WHEEL_UID='1000'
[ "$(id -u)" == "${WHEEL_UID}" ] || {
  echo 'unexpected user'
  exit 1
}

[ $# -lt 2 ] && {
  echo 'usage:'
  echo "  $0 user@email show_account"
  echo "  $0 user@email revoke --cert-path /home/certbot/user@email/live/domain.com/cert.pem"
  echo "  $0 user@email unregister"
  echo '  etc.'
  exit 1
}

PROD=${PROD:-0}
ACCOUNT="$1"

server='https://acme-staging-v02.api.letsencrypt.org/directory'
[ "${PROD}" == 1 ] && server="https://acme-v02.api.letsencrypt.org/directory"

shift

cmd="certbot $@ \
  --email ${ACCOUNT} \
  --config-dir ~/${ACCOUNT} \
  --work-dir ~/${ACCOUNT} \
  --logs-dir ~/${ACCOUNT} \
  --server ${server}"
echo "${cmd}"

sudo su certbot -c -- "${cmd}"
