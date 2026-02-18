#!/usr/bin/env bash

logger "running $0"

for i in podman docker ; do
  which $i && {
    $i image prune --all --force
    $i volume prune --force
    $i network prune --force
    $i builder prune --force
    #$i rmi --all --force
  }
done

which flatpak && flatpak uninstall --unused --noninteractive

# keep currently installed packages only
apk cache -v sync 2>> /dev/stdout | logger

# remove at least 30 days old non-dot files/directories
find /coredumps/ /home/*/Downloads/ -mindepth 1 -not -path '*/.*' -mtime +30 -exec rm -fr {} +

# remove at least 1y old rotated logs
find /var/log/ -mindepth 1 -path '*/*.gz' -mtime +365 -exec rm -f {} +

find /root/tmp/.vimundo/ -type f -mtime +90 -delete
find /root/tmp/.vimswaps/ -type f -mtime +90 -delete
find /home/*/tmp/.vimundo/ -type f -mtime +90 -delete
find /home/*/tmp/.vimswaps/ -type f -mtime +90 -delete

find / -xdev -type d -name __MACOSX -exec rm -rf {} +
