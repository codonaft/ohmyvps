#!/usr/bin/env bash

logger 'apk-autoupgrade'

APKS=(
  i2pd
  nginx
  openssh
  tinyproxy
  tor
)

declare -Ag version_signatures
declare -Ag services

installed_apks() {
  apk list --installed | grep -E "^$1-[0-9]{1,}" | awk '{print $1}'
}

apks_version_signature() {
  installed_apks "$1" | sha256sum -
}

apks_changed() {
  [[ "${version_signatures[$1]}" != $(apks_version_signature "$1") ]]
}

services[openssh]='sshd'
for i in ${APKS[@]} ; do
  version_signatures["$i"]=$(apks_version_signature "$i")
  [ "${services[$i]}" = '' ] && services["$i"]="$i"
done

eject || :
setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/latest-stable/{main,community} || :
apk add --no-cache --upgrade apk-tools 2>>/dev/stdout | logger || :
apk upgrade --no-cache 2>>/dev/stdout | logger
apk del doas linux-lts openssh-server-pam syslinux tiny-cloud-alpine tiny-cloud || :
rm -f /etc/motd

sync
echo 3 > /proc/sys/vm/drop_caches
for i in $(grep -E '^/dev' < /proc/mounts | awk '{print $2}') ; do
  fstrim -v "$i" 2>>/dev/stdout | logger || :
done

onidle.py 2>>/dev/stdout | logger || :

if [ -d "/lib/modules/$(uname -r)" ]; then
  logger 'kernel is the same'
  for i in ${APKS[@]} ; do
    apks_changed "$i" && rc-service --ifstarted "${services[$i]}" restart 2>>/dev/stdout | logger || :
  done
else
  kernel_apk=$(installed_apks 'linux-virt' | head -n1)
  logger "current kernel is $(uname -r), received a new kernel ${kernel_apk}, rebooting"
  reboot
fi
