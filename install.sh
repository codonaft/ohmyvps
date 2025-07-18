#!/usr/bin/env sh
#
# MIT License
#
# Copyright (c) 2024—∞ Alexander Lopatin (https://codonaft.com)
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

# https://alpinelinux.org/keys/ncopa.asc
# https://github.com/search?q=org%3Aalpinelinux%20ncopa.asc&type=code
ALPINE_GPG='-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

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
Mkc=
=FcYC
-----END PGP PUBLIC KEY BLOCK-----'

download_and_unpack() {
  wget https://api.github.com/repos/codonaft/ohmyvps/tarball -O - | tar xzf -
}

if [ "$(id -u)" != "0" ] ; then
  echo 'You need to be root'
  exit 1
fi

NET_IFACE=$(ip route | grep default | awk '{print $5}')
which apk && setup-apkrepos -1 && sed --in-place "/^\/.*/d;s!^#http!http!;s!^http:!https:!" /etc/apk/repositories && apk add bash gnupg htop iptables rsync tmux vim wget yq
which apt && apt -y install bash gnupg htop iptables rsync tmux vim wget yq

echo 'applying firewall rules'
iptables -F
iptables -X
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i "${NET_IFACE}" -j DROP

os="Alpine Linux"
grep Ubuntu /etc/*release && os="Gentoo Linux"

clear
echo "1. Install ${os}"
echo '2. Boot Alpine Linux'
echo

default_choice='1'
read -p "What's next? [${default_choice}] " choice
choice="${choice:-${default_choice}}"

[ "${choice}" = 2 ] && os="Boot Alpine Linux"

case "${os}" in
    "Alpine Linux")
        download_and_unpack
        *ohmyvps*/alpine/install.sh
        ;;
    "Gentoo Linux")
        download_and_unpack
        *ohmyvps*/gentoo/01-run-tmux.sh
        ;;
    "Boot Alpine Linux")
        ARCH='x86_64'
        MIRROR="https://dl-cdn.alpinelinux.org/alpine"
        VERSION_REQUEST='.[] | select(.title == "Virtual") | .version'

        latest_releases=$(wget -qO - "${MIRROR}/latest-stable/releases/${ARCH}/latest-releases.yaml")
        default_version=$(yq --output-format props "${VERSION_REQUEST}" <<< "${latest_releases}")
        [ "${default_version}" = '' ] && default_version=$(yq --raw-output "${VERSION_REQUEST}" <<< "${latest_releases}")
        [ "${default_version}" = '' ] && default_version='3.21.3'

        echo
        read -p "Version? [${default_version}] " version
        echo
        version=${version:-${default_version}}
        short_version=$(echo ${version} | sed 's!\.[0-9]*$!!')

        set -x

        iso="alpine-virt-${version}-${ARCH}.iso"
        url="${MIRROR}/v${short_version}/releases/${ARCH}/${iso}"

        wget -c "${url}"{,.sha256,.asc}
        sha256sum -c "${iso}.sha256"

        echo "${ALPINE_GPG}" | gpg --import
        gpg --verify "${iso}"{.asc,}

        mount -t iso9660 "${iso}" /mnt
        cp -a /mnt/* / || :
        cp -a /mnt/* /boot/ || : # in case if you have a separate /boot partition and the rest of stuff on LVM
        umount /mnt

        find /etc/default/grub* -type f -print0 | xargs -0 sed --in-place 's!^GRUB_TIMEOUT=.*!GRUB_TIMEOUT=1!;s!^GRUB_TIMEOUT_STYLE=.*!GRUB_TIMEOUT_STYLE=menu!'
        echo '#!/bin/sh
          cat << EOF
          menuentry "Alpine Linux" --unrestricted {
            linux /boot/vmlinuz-virt random.trust_cpu=off
            initrd /boot/initramfs-virt
          }
          EOF' > /etc/grub.d/99_custom
        chmod +x /etc/grub.d/99_custom
        update-grub
        grub-reboot 'Alpine Linux'

        sync
        echo 3 > /proc/sys/vm/drop_caches
        reboot
        ;;
    *)
        ;;
esac
