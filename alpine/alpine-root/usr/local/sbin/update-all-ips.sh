#!/usr/bin/env bash

update-banlist-dns.sh &
update-bot-ips.sh &
update-cloudflare-ips.sh &
update-google-ips.sh &
update-nginx-allowlist.sh &

wait

logger 'updated all IPs'
