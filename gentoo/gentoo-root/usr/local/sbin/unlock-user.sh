#!/usr/bin/env bash

[ $# = 1 ] || {
    echo "$0 username"
    exit 1
}

usermod -p '*' "$1"
faillock --user "$1" --reset
passwd -u "$1"
