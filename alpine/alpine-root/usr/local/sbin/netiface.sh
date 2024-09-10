#!/bin/sh

grep '^auto e' /etc/network/interfaces | awk '{print $2}' | head -n1
