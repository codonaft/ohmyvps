#!/usr/bin/env bash

[ -f /etc/init.d/tor ] && {
  sudo -u nobody curl -I --insecure --socks5-hostname '127.0.0.1:9050' 'http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion' || rc-service tor restart
}
