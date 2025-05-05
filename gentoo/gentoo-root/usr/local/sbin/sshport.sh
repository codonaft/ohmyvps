#!/usr/bin/env bash

( grep -E '^Port [0-9]*$' /etc/ssh/sshd_config || echo 'Port 22' ) | awk '{print $2}'
