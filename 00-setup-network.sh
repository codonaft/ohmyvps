#!/usr/bin/env bash
#
# MIT License
#
# Copyright (c) 2024—∞ Alexander Lopatin (https://codonaft.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

NET_IFACE="eth0"
IP_ADDR="11.22.33.44/24"
GATEWAY="11.22.0.1"
DNS="8.8.8.8"

# Some distros do nasty things with network;
# you may want to keep it up instead
LOOP="1"

function enable_network() {
    logger 'enable network'
    ip addr add "${IP_ADDR}" dev "${NET_IFACE}"
    ip route add default via "${GATEWAY}" dev "${NET_IFACE}"
    ip link set dev "${NET_IFACE}" up
}

function set_dns() {
    logger 'set dns'
    echo "nameserver ${DNS}" > /etc/resolv.conf
}

set -x

if [ "$(id -u)" != "0" ]; then
    echo 'You need to be root'
    exit 1
fi

logger 'apply firewall rules'
iptables -F
iptables -X
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i "${NET_IFACE}" -j DROP

if [ "${LOOP}" = "0" ] ; then
    enable_network
else
    while true ; do
        ip addr show "${NET_IFACE}" | grep --silent "${IP_ADDR}" || enable_network
        grep --silent "^nameserver ${DNS}$" /etc/resolv.conf || set_dns
        sleep 3
    done
fi
