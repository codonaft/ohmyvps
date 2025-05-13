#!/usr/bin/env bash

if [ $# -ne 1 ] ; then
    echo "syntax $0 ip_address"
    exit 1
fi

ip="$1"
[ -e "${SSH_BANLIST}" ] && sed --in-place "/^${ip}$/d" "${SSH_BANLIST}"

iptables -D INPUT -p tcp --source "${ip}" --dport "${SSH_PORT}" -j DROP
