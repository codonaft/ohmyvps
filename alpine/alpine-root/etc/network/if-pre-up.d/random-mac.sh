#!/usr/bin/env sh

exit
if [[ "${IFACE}" == e* || "${IFACE}" == w* ]] ; then
  which macchanger && macchanger --random --another "${IFACE}" || \
    ip link set dev "${IFACE}" addr $(openssl rand -hex 6 | sed 's|..|&:|g;s|:$||')
fi
