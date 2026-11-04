#!/usr/bin/env bash

if [ $# -ne 1 ] ; then
    echo "syntax $0 ip_address"
    exit 1
fi

ip="$1"
[ -e "${SSH_BANLIST}" ] && sed --in-place "/^${ip}$/d" "${SSH_BANLIST}"

nft add rule inet filter input ip saddr "${ip}" tcp dport "${SSH_PORT}" drop || \
  nft add rule inet filter input ip6 saddr "${ip}" tcp dport "${SSH_PORT}" drop || :
