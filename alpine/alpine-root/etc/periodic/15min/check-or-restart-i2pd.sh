#!/usr/bin/env bash

[ -f /etc/init.d/i2pd ] && {
  sudo -u nobody curl -I --insecure --max-time 120 --proxy '127.0.0.1:4444' 'http://reg.i2p' || rc-service i2pd restart
}
