#!/usr/bin/env bash

reload_rules=0

update-banlist-dns.sh &

update-nginx-allowlist.sh && logger 'updated nginx allowlist IPs'
update-bot-ips.sh && logger 'updated bot IPs' && reload_rules=1
update-cloudflare-ips.sh && logger 'updated Cloudflare IPs' && reload_rules=1
update-google-ips.sh && logger 'updated Google IPs' && reload_rules=1

[ "${reload_rules}" = 1 ] && rc-service --ifstarted local restart | logger

wait
