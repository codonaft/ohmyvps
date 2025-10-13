#!/usr/bin/env bash

reload_rules=0

update-allowlist-ips.sh && logger 'updated allowlist IPs' && reload_rules=1
update-google-ips.sh && logger 'updated Google IPs' && reload_rules=1
update-cloudflare-ips.sh && logger 'received new Cloudflare IPs' && reload_rules=1

[ "$reload_rules" = 1 ] && /etc/init.d/local restart | logger
