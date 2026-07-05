#!/usr/bin/env bash

source /etc/profile.d/99local.sh

[ -f /etc/init.d/tor ] && {
  sudo -u nobody dig -p ${TOR_DNS_PORT} +tcp +timeout=120 www.cloudflare.com | grep NOERROR || rc-service tor restart
}
