#!/usr/bin/env bash

logger 'apk-autoupgrade'

installed_apk () {
  apk list --installed | grep -E "^$1-[0-9]{1,}" | head -n1 | awk '{print $1}'
}

openssh_apk=$(installed_apk 'openssh')
nginx_apk=$(installed_apk 'nginx')

eject || :
setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/latest-stable/{main,community} || :
apk add --no-cache --upgrade apk-tools 2>>/dev/stdout | logger || :
apk upgrade --no-cache 2>>/dev/stdout | logger
apk del doas linux-lts openssh-server-pam syslinux tiny-cloud-alpine tiny-cloud || :
rm -f /etc/motd

sync
echo 3 > /proc/sys/vm/drop_caches
fstrim -v / 2>>/dev/stdout | logger

onidle.py 2>>/dev/stdout | logger || :

if [ -d "/lib/modules/$(uname -r)" ]; then
  logger 'kernel is the same'
  [ "${openssh_apk}" = $(installed_apk 'openssh') ] || rc-service --ifstarted sshd restart 2>>/dev/stdout | logger || :
  [ "${nginx_apk}" = $(installed_apk 'nginx') ] || rc-service --ifstarted nginx restart 2>>/dev/stdout | logger || :
else
  kernel_apk=$(installed_apk 'linux-virt')
  logger "current kernel is $(uname -r), received a new kernel ${kernel_apk}, rebooting"
  reboot
fi
