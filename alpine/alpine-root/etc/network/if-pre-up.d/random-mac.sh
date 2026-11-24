#!/usr/bin/env sh

exit
case "${IFACE}" in
  e*|w*)
    if which macchanger ; then
      macchanger --random --another "${IFACE}"
    else
      ip link set dev "${IFACE}" addr $(openssl rand -hex 6 | sed 's|..|&:|g;s|:$||')
    fi
    ;;
  *)
    ;;
esac
