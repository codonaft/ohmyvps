#!/usr/bin/env bash

SSH_PORT="SSH_PORT_WILL_BE_AUTOMATICALLY_REPLACED"

if [ $# -ne 1 ] ; then
    echo "syntax $0 ip_address"
    exit 1
fi

ip="$1"
[ -e /var/tmp/banlist.txt ] && sed --in-place "/^${ip}$/d" /var/tmp/banlist.txt

iptables -D INPUT -p tcp --source "${ip}" --dport "${SSH_PORT}" -j DROP
