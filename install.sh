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

export PACKAGES='bash git gnupg htop nftables rsync sed tmux vim wget yq'
export ALPINE_MIRROR='https://dl-cdn.alpinelinux.org/alpine'

BOOT_AND_INSTALL_ALPINE='Boot and Install Alpine'
INSTALL_ALPINE='Install Alpine'
INSTALL_GENTOO='Install Gentoo'

export ENABLE_FIREWALL='enable_firewall() {
  echo "applying firewall rules"
  nft flush ruleset
  nft add table inet filter
  nft add chain inet filter input "{ type filter hook input priority 0; policy accept; }"
  nft add rule inet filter input iifname "lo" accept
  nft add rule inet filter input "tcp flags != syn / fin,syn,rst,ack" ct state new drop
  nft add rule inet filter input ct state invalid drop
  nft add rule inet filter input ct state related,established accept
  nft add rule inet filter input drop
}'

export WAN_IS_UP='wan_is_up() {
  ip link show up | grep -E "^[0-9]*: [ew].* state UP"
}'

export MAYBE_SET_APK_REPOS="maybe_set_apk_repos() {
  if which apk && wan_is_up ; then
    chattr -i /etc/apk/repositories || :
    short_version=\$(sed 's|\\.[0-9]*$||' </etc/alpine-release)
    alpine_current=\${ALPINE_MIRROR}/v\${short_version}
    setup-apkrepos \${alpine_current}/main \${alpine_current}/community
  fi
}"

export SYNC_ALL='sync_all() {
  sync
  echo 3 >/proc/sys/vm/drop_caches
}'

maybe_clone_ohmyvps() {
  [ -d /ohmyvps ] && return

  rm -rf /ohmyvps
  for i in https://github.com/codonaft/ohmyvps ; do
    git clone --depth=1 "$i" ohmyvps && break
  done
}

for i in "${ENABLE_FIREWALL}" "${WAN_IS_UP}" "${MAYBE_SET_APK_REPOS}" "${SYNC_ALL}" ; do
  eval "$i"
done

cd /

if [ "$(id -u)" != '0' ] ; then
  echo 'You need to be root'
  exit 1
fi

choice=''
if [ "$#" -ne '0' ] ; then
  choice="$1"
fi

maybe_set_apk_repos

if wan_is_up ; then
  set -- "${PACKAGES}"
  which apk && apk add $@
  which apt && apt -y --no-install-recommends install $@

  enable_firewall
  maybe_clone_ohmyvps
fi

if [ -d /.modloop ] ; then
  echo "1. ${INSTALL_ALPINE}"
else
  echo "1. ${BOOT_AND_INSTALL_ALPINE}"
fi
echo "2. ${INSTALL_GENTOO}"

if [ -z "${choice}" ] ; then
  default_choice='1'
  echo
  read -p "What's next? [${default_choice}] " choice
  choice="${choice:-${default_choice}}"
fi

if [ "${choice}" = '1' ] ; then
  if [ -d /.modloop ] ; then
    action="${INSTALL_ALPINE}"
  else
    action="${BOOT_AND_INSTALL_ALPINE}"
  fi
else
  action="${INSTALL_GENTOO}"
fi

case "${action}" in
  "${BOOT_AND_INSTALL_ALPINE}")
    ohmyvps/alpine/01-boot.sh
    ;;
  "${INSTALL_ALPINE}")
    for i in readline bash macchanger sed ; do
      apk add --force-non-repository "/var/cache/apk/$i"*.apk || :
    done
    ohmyvps/alpine/03-install.sh
    ;;
  "${INSTALL_GENTOO}")
    ohmyvps/gentoo/01-run-tmux.sh
    ;;
  *)
    ;;
esac
