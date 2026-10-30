#!/usr/bin/env bash

reload_rules=0

update-banlist-dns.sh &

update-allowlist-ips.sh && logger 'updated allowlist IPs' && reload_rules=1
update-bot-ips.sh && logger 'updated bot IPs' && reload_rules=1
update-cloudflare-ips.sh && logger 'updated Cloudflare IPs' && reload_rules=1
update-google-ips.sh && logger 'updated Google IPs' && reload_rules=1

[ "$reload_rules" = 1 ] && /etc/init.d/local --verbose restart | logger

wait
