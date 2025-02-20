#!/usr/bin/env bash

logger 'apk-autoupgrade'

eject || :
setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/latest-stable/{main,community} || :
apk add --no-cache --upgrade apk-tools 2>>/dev/stdout | logger || :
apk upgrade --no-cache 2>>/dev/stdout | logger
apk del doas linux-lts openssh-server-pam syslinux tiny-cloud-alpine tiny-cloud || :
rm -f /etc/motd
# TODO: detect nginx and sshd update, restart them
