#!/usr/bin/env bash

logger "running $0"

which docker && {
    docker image prune --all --force
    docker volume prune --force
    docker network prune --force
    docker builder prune --force
}

which flatpak && flatpak uninstall --unused --noninteractive

eclean -d distfiles
#eclean -d packages

# remove at least 30 days old non-dot files/directories
find /coredumps/ /home/*/Downloads/ /var/tmp/portage/ -mindepth 1 -not -path '*/.*' -mtime +30 -exec rm -fr {} +

find /root/.vimundo/ -type f -mtime +90 -delete
find /root/.vimswaps/ -type f -mtime +90 -delete
find /home/*/.vimundo/ -type f -mtime +90 -delete
find /home/*/.vimswaps/ -type f -mtime +90 -delete

find / -xdev -type d -name __MACOSX -exec rm -rf {} +
