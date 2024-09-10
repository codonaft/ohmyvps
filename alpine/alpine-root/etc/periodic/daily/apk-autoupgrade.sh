#!/usr/bin/env bash

ALPINE_VERSION="VERSION_WILL_BE_AUTOMATICALLY_REPLACED"

logger 'apk-autoupgrade'

eject || :
setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/{main,community} || :
apk upgrade --no-cache 2>>/dev/stdout | logger
apk del doas linux-lts openssh-server-pam syslinux tiny-cloud-alpine tiny-cloud || :
# TODO: detect nginx and sshd update, restart them
