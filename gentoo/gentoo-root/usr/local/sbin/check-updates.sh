#!/usr/bin/env bash

ps uax | grep '/emerge ' | grep -v grep >> /dev/null && exit 0
#emaint sync --allrepos
emerge --sync
emerge --regen
eix-update

security_updates=$(glsa-check -tp affected | grep vulnerable: | wc -l)
updates=$(emerge -pvuDN --ignore-built-slot-operator-deps=y @system @world 2>>/dev/stdout | grep -E '^Total' | tail -n1 | sed 's! (.*!!')

updates="emerge updates: Security: ${security_updates} packages, ${updates}"
logger "${updates}"

export EMERGE_DEFAULT_OPTS=""
emerge -fvuDN --ignore-built-slot-operator-deps=y @system @world
