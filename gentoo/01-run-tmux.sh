#!/usr/bin/env bash

set -xeuo pipefail

script_dir=$(realpath "$(dirname "$0")")
cd "${script_dir}"

if [ "$(id -u)" != "0" ] ; then
    echo 'You need to be root'
    exit 1
fi

possible_net_gateway=$(/bin/ip route | grep '^default via ' | awk '{print $3}')
possible_net_iface=$(/bin/ip route | grep '^default via ' | awk '{print $5}')
if [ "${possible_net_iface}" = '' ] ; then
    possible_net_iface=$(ip -o link | grep 'state UP' | grep '^[0-9]*: e' | awk '{print $2}' | sed 's!:!!')
fi

if [ "${possible_net_iface}" != '' ] ; then
    possible_net_ip=$(ip -family inet addr show "${possible_net_iface}" | grep 'inet ' | awk '{print $2}')
    [ "${possible_net_iface}" != '' ] && sed --in-place "s!NET_IFACE='UNDETECTED_PLEASE_FILL_OUT'!NET_IFACE='${possible_net_iface}'!g" 02-config.sh
    [ "${possible_net_ip}" != '' ] && sed --in-place "s!config_NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED='UNDETECTED_PLEASE_FILL_OUT'!config_NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED='${possible_net_ip}'!g" gentoo-root/etc/conf.d/net || :
    [ "${possible_net_gateway}" != '' ] && sed --in-place "s!routes_NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED='default via UNDETECTED_PLEASE_FILL_OUT'!routes_NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED='default via ${possible_net_gateway}'!g" gentoo-root/etc/conf.d/net || :
fi

edit_configs_cmd='vim -p 02-config.sh'
[ -e gentoo-root ] && edit_configs_cmd='vim -u gentoo-root/root/.vimrc -p 02-config.sh gentoo-root/etc/{conf.d/net,portage/make.conf}'

tmux -f .tmux.conf new-session -s ohmyvps -d || :
sleep 0.5
tmux send-keys -t ohmyvps:1 "${edit_configs_cmd}" || :
sleep 0.5
tmux send-keys -t ohmyvps:2 './03-install.sh' || :
tmux attach-session -t ohmyvps
