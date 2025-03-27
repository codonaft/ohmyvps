#!/usr/bin/env python

from datetime import datetime, timedelta, UTC
from os import path
from subprocess import getoutput
from time import sleep
import psutil
import sys

TIMEOUT = timedelta(hours=2)
NGINX_MIN_DELTA_ACCESS = timedelta(minutes=1)
MAX_ALLOWLIST_BANDWIDTH_BYTES_PER_SEC = 50 * 1024
CRITIAL_PROCESSES = {'apk', 'fstrim', 'rsync'}

BANDWIDTH_DELTA_TIME_SEC = 10
ALLOWLIST = '/etc/ssh/allowlist.txt'

PRE_MESSAGE = path.splitext(path.basename(sys.argv[0]))[0] + ':'
PRINTED_MESSAGES = set()

INTERVAL = 0
BEGIN = datetime.now(UTC)


def info(message):
    if message not in PRINTED_MESSAGES:
        PRINTED_MESSAGES.add(message)
        print(PRE_MESSAGE, message)

def is_nginx_active():
    try:
        grep = getoutput(f"grep -EoR 'access_log\\s.*;' /etc/nginx/").split('\n')
        nginx_logs = set(i.split(':', 1)[1].split('access_log', 1)[1].strip().split()[0].strip() for i in grep)
        nginx_logs_pattern = ' '.join(nginx_logs)
        tail = getoutput(f"tail --lines=100 {nginx_logs_pattern} | grep -E ' HTTP/[0-9.]{{1,}}\" 200 ' | grep -Eo '(\\[.*\\])'").split('\n')
        deltas = [now - datetime.strptime(i, '[%d/%b/%Y:%H:%M:%S %z]') for i in tail if len(i) > 0]
        return len(deltas) > 0 and min(deltas) < NGINX_MIN_DELTA_ACCESS
    except Exception as e:
        info(e)
        return False

def bandwidth():
    try:
        nets = (net for net in open(ALLOWLIST).readlines() if len(net.strip()) > 0)
        pattern = ' or '.join(f'net {net}' for net in nets)
        tshark = getoutput(f'timeout {BANDWIDTH_DELTA_TIME_SEC}s tshark -i $(netiface.sh) -f "({pattern}) and (tcp or udp)" -T fields -e frame.len 2>>/dev/null').split('\n')
        return sum(int(i) for i in tshark if len(i) > 0) // BANDWIDTH_DELTA_TIME_SEC
    except Exception as e:
        info(e)
        return 0

if len(sys.argv) > 1:
    info("this script waits for potentially best time to reboot")
    info("exits with 1 if it's reached a timeout")
    info("exits with 0 if there's no useful activity")
    sys.exit()

info('waiting until OS becomes idle')
while True:
    sleep(INTERVAL)
    INTERVAL = 1

    now = datetime.now(UTC)
    if now - BEGIN >= TIMEOUT:
        info('timeout elapsed')
        sys.exit(1)

    detected_processes = CRITIAL_PROCESSES.intersection(i.info['name'] for i in psutil.process_iter(['name']))
    if len(detected_processes) > 0:
        info('detected critical processes', detected_processes)
        continue

    if is_nginx_active():
        info('detected nginx activity')
        continue

    allowlist_bandwidth = bandwidth()
    if allowlist_bandwidth > MAX_ALLOWLIST_BANDWIDTH_BYTES_PER_SEC:
        info(f'detected allowlist activity {allowlist_bandwidth // 1024} KiB/s')
        continue

    info('OS is currently idle')
    sys.exit(0)
