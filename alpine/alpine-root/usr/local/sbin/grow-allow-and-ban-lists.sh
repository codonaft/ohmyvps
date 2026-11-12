#!/usr/bin/env bash

source /etc/profile.d/99local.sh

logger 'reload added items to allow/ban lists'

filter_ipv4 <"${SSH_ALLOWLIST}" | nft_list 'add element inet filter ssh_allow4' '' || :
filter_ipv6 <"${SSH_ALLOWLIST}" | nft_list 'add element inet filter ssh_allow6' '' || :

filter_ipv4 <"${LOCAL_BANLIST}" | nft_list 'add element inet filter ban4' '' || :
filter_ipv6 <"${LOCAL_BANLIST}" | nft_list 'add element inet filter ban6' '' || :

# allow HTTP/HTTPS traffic from Cloudflare IPs
nft_list 'add rule inet filter input ip saddr' 'tcp dport { 80, 443 } accept' </var/tmp/cloudflare-ipv4.txt || :
nft_list 'add rule inet filter input ip saddr' 'udp dport 443 accept' </var/tmp/cloudflare-ipv4.txt || :
nft_list 'add rule inet filter input ip6 saddr' 'tcp dport { 80, 443 } accept' </var/tmp/cloudflare-ipv6.txt || :
nft_list 'add rule inet filter input ip6 saddr' 'udp dport 443 accept' </var/tmp/cloudflare-ipv6.txt || :

# disallow traffic from bots
sort -u /var/tmp/{google,bots}-*-ipv4.txt | nft_list 'add rule inet filter input ip saddr' 'drop'
sort -u /var/tmp/{google,bots}-*-ipv6.txt | nft_list 'add rule inet filter input ip6 saddr' 'drop'

logger 'done'
