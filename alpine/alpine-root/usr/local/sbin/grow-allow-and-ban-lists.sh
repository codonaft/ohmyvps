#!/usr/bin/env bash

source /etc/profile.d/99local.sh

logger 'reload added items to allow/ban lists'

filter_ipv4 <"${SSH_ALLOWLIST}" | nft_list 'add element inet filter ssh_allow4' '' || :
filter_ipv6 <"${SSH_ALLOWLIST}" | nft_list 'add element inet filter ssh_allow6' '' || :

filter_ipv4 <"${LOCAL_BANLIST}" | nft_list 'add element inet filter ban4' '' || :
filter_ipv6 <"${LOCAL_BANLIST}" | nft_list 'add element inet filter ban6' '' || :

logger 'done'
