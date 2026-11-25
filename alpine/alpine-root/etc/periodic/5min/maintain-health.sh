#!/usr/bin/env bash

source /etc/profile.d/99local.sh

run_dig() {
  sudo -u nobody dig +timeout=60 "$@"
}

dns_check_and_fix() {
  domain="$1"
  if run_dig +tcp -p "${EXTERNAL_TOR_DNS_LOCAL_TCP_PORT}" "${domain}" | grep -q NOERROR ; then
    run_dig "${domain}" | grep -q NOERROR || rc-service coredns restart
  else
    page=http://$(sed 's|:.*||' <<<"${EXTERNAL_TOR_DNS}")
    curl --silent --head --proxy "socks5h://127.0.0.1:${TOR_SOCKS5_PORT}" "${page}" || rc-service tor restart
    for i in stop start ; do
      "/etc/local.d/04-tor-dns.$i"
    done
  fi
}

random_domain() {
  wget -qO- 'https://api.gentoo.org/mirrors/distfiles.xml' 'https://www.openbsd.org/ftp.html' 'https://archlinux.org/mirrorlist/?protocol=https&ip_version=4' |
    grep -oE 'https?://[^<"]+' |
    sed -E 's|https?://([^/:]+).*|\1|' |
    sort -u |
    shuf -n 1 || \
      echo 'cloudflare.com'
}

ps uax | grep " socat .*${EXTERNAL_TOR_DNS}" | grep -qv grep || {
  rc-service local restart
  exit
}

[ -f /etc/init.d/tor ] && {
  dns_check_and_fix $(random_domain) &
}

[ -f /etc/init.d/i2pd ] && {
  sudo -u nobody curl -I --insecure --max-time 120 --proxy '127.0.0.1:4444' 'http://reg.i2p' || rc-service i2pd restart &
}

wait

rc-service --ifcrashed coredns i2pd tor start || :
