#!/usr/bin/env bash

fstrim -v / 2>>/dev/stdout | logger
