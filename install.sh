#!/usr/bin/env sh
#
# MIT License
#
# Copyright (c) 2024—∞ npub1alptdev5srcw2hxg03567p4k6xs3lgj7f6545suc0rzp0xw98svse7rg94 (https://codonaft.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -eu

ALPINE_MIRROR='https://dl-cdn.alpinelinux.org/alpine'
PACKAGES='bash git gnupg htop nftables rsync sed tmux vim wget yq'

BOOT_ALPINE='Boot Alpine'
INSTALL_ALPINE='Install Alpine'
INSTALL_GENTOO='Install Gentoo'

clone_ohmyvps() {
  path="$1"
  rm -rf ohmyvps
  for i in https://github.com/codonaft/ohmyvps ; do
    git clone --depth=1 "$i" "${path}/ohmyvps" && break
  done
}

enable_firewall() {
  echo 'applying firewall rules'
  nft flush ruleset
  nft add table inet filter
  nft add chain inet filter input '{ type filter hook input priority 0; policy accept; }'
  nft add rule inet filter input iifname 'lo' accept
  nft add rule inet filter input 'tcp flags != syn / fin,syn,rst,ack' ct state new drop
  nft add rule inet filter input ct state invalid drop
  nft add rule inet filter input ct state related,established accept
  nft add rule inet filter input drop
}

wan_is_up() {
  ip link show up | grep -E '^[0-9]*: [ew].* state UP'
}

if [ "$(id -u)" != '0' ] ; then
  echo 'You need to be root'
  exit 1
fi

if wan_is_up ; then
  set -- "${PACKAGES}"
  which apk && {
    chattr -i /etc/apk/repositories || :
    short_version=$(sed 's|\.[0-9]*$||' </etc/alpine-release)
    alpine_current="${ALPINE_MIRROR}/v${short_version}"
    setup-apkrepos "${alpine_current}/main" "${alpine_current}/community" && apk add $@
  }
  which apt && apt -y --no-install-recommends install $@

  enable_firewall
  clone_ohmyvps '.'
fi

clear
if [ -d /.modloop ] ; then
  echo "1. ${INSTALL_ALPINE}"
  echo "2. ${INSTALL_GENTOO}"
else
  echo "1. ${BOOT_ALPINE}"
  echo "2. ${INSTALL_GENTOO}"
fi
echo

default_choice='1'
read -p "What's next? [${default_choice}] " choice
choice="${choice:-${default_choice}}"

if [ "${choice}" = 1 ] ; then
  if [ -d /.modloop ] ; then
    action="${INSTALL_ALPINE}"
  else
    action="${BOOT_ALPINE}"
  fi
else
  action="${INSTALL_GENTOO}"
fi

case "${action}" in
  "${BOOT_ALPINE}")
    ohmyvps/alpine/boot.sh "${ALPINE_MIRROR}"
    ;;
  "${INSTALL_ALPINE}")
    bash -c "
      $(declare -f wan_is_up)
      $(declare -f enable_firewall)
      $(declare -f clone_ohmyvps)
      $(cat ohmyvps/alpine/install.sh)
    "
    ;;
  "${INSTALL_GENTOO}")
    ohmyvps/gentoo/01-run-tmux.sh
    ;;
  *)
    ;;
esac
