#!/usr/bin/env bash

logger 'apk-autoupgrade'

eject || :
alpine_version=$(grep -oE '[0-9]+\.[0-9]+' /etc/alpine-release)
setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/{main,community} || :
apk upgrade --no-cache 2>>/dev/stdout | logger
apk del doas linux-lts openssh-server-pam syslinux tiny-cloud-alpine tiny-cloud || :
# TODO: detect nginx and sshd update, restart them
