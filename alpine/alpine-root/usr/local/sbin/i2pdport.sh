#!/usr/bin/env sh

grep -E '^port\s*=\s*[0-9]*' /etc/i2pd/i2pd.conf | sed 's!^port\s*=\s*!!'
