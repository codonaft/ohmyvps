#!/usr/bin/env bash

SSH_PORT=$(sshport.sh)
BANLIST="/etc/ssh/banlist.txt"

if [ $# -ne 1 ] ; then
    echo "syntax $0 ip_address"
    exit 1
fi

ip="$1"
[ -e "${BANLIST}" ] && sed --in-place "/^${ip}$/d" "${BANLIST}"

iptables -D INPUT -p tcp --source "${ip}" --dport "${SSH_PORT}" -j DROP
