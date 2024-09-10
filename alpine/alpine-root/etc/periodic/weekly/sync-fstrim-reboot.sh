#!/usr/bin/env bash

sync
echo 3 > /proc/sys/vm/drop_caches
fstrim -v / 2>>/dev/stdout | logger

[ -d "/lib/modules/$(uname -r)" ] || {
  kernel_apk=$(apk list --installed | grep -E '^linux-virt' | awk '{print $1}')
  echo "current kernel is $(uname -r) received a new kernel ${kernel_apk}, rebooting" | logger
  reboot
}
