#!/usr/bin/env bash

watch --no-title --interval 10 'df --human-readable ; echo ; echo -n "http connections: " ; ss --no-header -tn state established "( sport = :80 or sport = :443 )" | wc -l'
