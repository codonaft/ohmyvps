#!/usr/bin/env bash

source /etc/profile.d/99local.sh

logger 'reloading local banlist'

filter_ipv4 < "${LOCAL_BANLIST}" | nft_list 'add element inet filter ban4' '' || :
filter_ipv6 < "${LOCAL_BANLIST}" | nft_list 'add element inet filter ban6' '' || :

logger 'done'
