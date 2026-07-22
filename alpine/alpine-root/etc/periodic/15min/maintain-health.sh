#!/usr/bin/env bash

source /etc/profile.d/99local.sh

ps uax | grep -E " socat .*${TOR_DNS_HOST}" | grep -v grep >>/dev/null || {
  rc-service local restart
}

[ -f /etc/init.d/tor ] && {
  sudo -u nobody dig -p ${TOR_DNS_PORT} +tcp +timeout=120 www.cloudflare.com | grep NOERROR || rc-service tor restart
}

[ -f /etc/init.d/i2pd ] && {
  sudo -u nobody curl -I --insecure --max-time 120 --proxy '127.0.0.1:4444' 'http://reg.i2p' || rc-service i2pd restart
}
