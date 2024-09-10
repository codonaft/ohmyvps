#!/usr/bin/env python3

import ipaddress
import sys

addr = ipaddress.ip_address(sys.argv[1])
allowed_cidrs = (
  ipaddress.ip_network(i.strip())
  for i in sys.stdin.read().strip().split('\n') if len(i.strip()) > 0
)

for i in allowed_cidrs:
    if addr in i:
        sys.exit(0)

sys.exit(1)
