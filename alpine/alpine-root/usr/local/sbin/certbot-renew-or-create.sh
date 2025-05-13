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

set -xeuo pipefail

source /etc/profile.d/99local.sh

WEBROOT_PATH='/var/www/certbot'
NGINX_CONF_DIR='/etc/nginx/locations'
MAX_DAYS_BEFORE_RENEW='30'

PROD=${PROD:-0}

server='https://acme-v02.api.letsencrypt.org/directory'
jitter=$(awk 'BEGIN{srand(); print int(rand()*(600+1))}')
output_dir="$3"
fullchain="${output_dir}/fullchain.pem"
privkey="${output_dir}/privkey.pem"
chain="${output_dir}/chain.pem"

[ "${PROD}" == 0 ] && {
  server='https://acme-staging-v02.api.letsencrypt.org/directory'
  jitter='2'
  fullchain="${fullchain}.staging"
  privkey="${privkey}.staging"
  chain="${chain}.staging"
}

[ -f /usr/sbin/nginx ] || {
  echo "nginx not found"
  exit 1
}

[ "$(id -u)" == "${WHEEL_UID}" ] || {
  echo 'unexpected user'
  exit 1
}

groups | grep -q "\b${ADMIN_GROUP}\b" || {
  echo "${USERNAME} is not an admin"
  exit 1
}

groups certbot | grep -q "\b${ADMIN_GROUP}\b" && {
  echo 'certbot is admin'
  exit 1
}

[ $# == 3 ] || {
  echo "usage: $0 domain1.com,subdomain.domain2.com user@email /etc/nginx/ssl/"
  echo "for manual actions use: certbot-control.sh user@email show_account"
  exit 1
}

domains="$1"
account="$2"
certbot_home='/home/certbot'
work_dir="${certbot_home}/${account}"
challenge_dir='.well-known/acme-challenge'
challege_full_dir="${WEBROOT_PATH}/${challenge_dir}"

[[ "${output_dir}" == /* ]] || {
  echo "unexpected full output path ${output_dir}"
  exit 1
}

sudo su -c "
set -xeuo pipefail

mkdir -p ${output_dir}
chown nginx:nginx ${output_dir}
chmod 00500 ${output_dir}

for i in ${fullchain} ${privkey} ${chain} ; do
  touch \$i
  chmod 400 \$i
  chown nginx:nginx \$i
done"

[ $(stat -c "%a" "${certbot_home}") == 700 ] || {
  echo "unexpected directory permissions"
  exit 1
}

expected="$(sudo -u certbot openssl rand -hex 32)"
expected_filename="test_$(sudo -u certbot openssl rand -hex 32)"
sudo su certbot -c "rm -fv ${challege_full_dir}/test_* ; echo -n ${expected} > ${challege_full_dir}/${expected_filename}"
sudo /etc/init.d/nginx status

IFS="," read -r -a domains_array <<< "${domains}"
for i in ${domains_array[@]} ; do
  url="http://$(echo $i | sed 's!^\*!!')/${challenge_dir}/${expected_filename}"
  echo "testing ${url}"
  actual=$(sudo -u certbot wget --no-hsts -qO - ${url})
  [ "${expected}" == "${actual}" ] || {
    echo 'nginx test failed'
    exit 1
  }
done
sudo su certbot -c "rm -fv ${challege_full_dir}/test_*"

first_domain=$(echo "${domains}" | cut -d',' -f1 | sed 's!^\*\.!!')
max_secs_before_renew=$((( MAX_DAYS_BEFORE_RENEW * 60 * 60 * 24 )))
#max_secs_before_renew=100000000000 # NOTE: debug

sudo cat "${fullchain}" | sudo -u certbot openssl x509 -checkend "${max_secs_before_renew}" -noout > /dev/null && {
  expiration_date=$(sudo cat "${fullchain}" | sudo -u certbot openssl x509 -noout -enddate | sed 's/notAfter=//')
  echo "Certificate ${first_domain} is not expiring yet, expiration date is ${expiration_date}"
  actual_domains=$(sudo cat "${fullchain}" | sudo -u certbot openssl x509 -text -noout | grep -E -o 'DNS.*' | sed 's!\s*DNS:!!g' | sort -u | tr '\n' ',')
  expected_domains=$(echo "${domains}" | tr ',' '\n' | sort -u | tr '\n' ',')
  if [ "${actual_domains}" == "${expected_domains}" ] ; then
    echo "Nothing to update, same domains: ${actual_domains}"
    exit 0
  else
    echo "Domains have changed: ${actual_domains} -> ${expected_domains}"
  fi
}

echo "sanity tests have passed, will be generating new certificate after ${jitter} seconds"
sleep "${jitter}"
echo 'generating certificate now'

sudo su certbot -c "
set -xeuo pipefail

cb() {
  certbot \$1 \
    --server ${server} \
    --noninteractive --agree-tos --preferred-challenges http-01 --force-renewal --key-type ecdsa \
    --max-log-backups 5 \
    --domains ${domains} --email ${account} \
    --config-dir ${work_dir} --work-dir ${work_dir} --logs-dir ${work_dir} --webroot --webroot-path ${WEBROOT_PATH}
}

chmod 00700 ~
mkdir -m 00700 -p ${work_dir}

cb show_account || cb register
cb certonly"

result_dir=$(sudo su certbot -c "ls -1d ${work_dir}/live/${first_domain}* | sort -u | tail -n1")

sudo su -c "
set -xeuo pipefail

cp --dereference -fv ${result_dir}/fullchain.pem ${fullchain}
cp --dereference -fv ${result_dir}/privkey.pem ${privkey}
cp --dereference -fv ${result_dir}/chain.pem ${chain}
chown nginx:nginx ${output_dir}/*
chmod 00400 ${output_dir}/*
/etc/init.d/nginx checkconfig
/etc/init.d/nginx reload
sync ${output_dir}/*"

echo "FINISHED, new certificate is applied"
