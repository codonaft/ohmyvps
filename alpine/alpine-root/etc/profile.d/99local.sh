export RUSTFLAGS='-C target-cpu=native -C force-frame-pointers=y'
export CFLAGS='-O3 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all -fstack-clash-protection --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always'
export CXXFLAGS='-O3 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all -fstack-clash-protection --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always'
export FCFLAGS='-O3 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all -fstack-clash-protection --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always'
export FFLAGS='-O3 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all -fstack-clash-protection --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always'
export LDFLAGS='-Wl,-z,now -Wl,-z,relro'

export SYSLOG='/tmp/messages'

export EDITOR='vim'

export WHEEL_UID='1000'
export ADMIN_GROUP='wheel'

export LOCAL_BANLIST='/var/tmp/local-banlist.txt'
export DNS_BANLIST='/var/tmp/dns-banlist.txt'
export SSH_BANLIST='/etc/ssh/banlist.txt'
export SSH_ALLOWLIST='/etc/ssh/allowlist.txt'

export SSH_PORT=$( ( grep -E '^Port\s*[0-9]*$' /etc/ssh/sshd_config || echo 'Port 22' ) | awk '{print $2}' | head -n1 )

export NET_IFACE=$(grep -E '^auto (e|w)' /etc/network/interfaces | awk '{print $2}' | head -n1)
export NET_IPV4=$(grep -A 3 -E '^auto (e|w)' /etc/network/interfaces | grep address | awk '{print $2}' | grepcidr -e '0.0.0.0/0' | head -n1)
export NET_IPV6_GW=$(grep '^\s*gateway' /etc/network/interfaces | awk '{print $2}' | grepcidr -e '::/0' | head -n1)

export TOR_SOCKS5_PORT=$(grep '^\s*SocksPort\s*' /etc/tor/torrc | grepcidr -e '0.0.0.0/0' | grep -oE ':[0-9]*(\s|$)' | sed 's!:!!;s!\s*!!g' | head -n1)
export TOR_ONION_DNS_UDP_PORT=$(grep '^\s*DNSPort' /etc/tor/torrc | grepcidr -e '0.0.0.0/0' | grep -oE ':[0-9]*(\s|$)' | sed 's!:!!;s!\s*!!g' | head -n1)

export EXTERNAL_TOR_DNS='dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion:53'
export EXTERNAL_TOR_DNS_LOCAL_TCP_PORT='5350'

export UNBOUND_DNS_PORT=$(grep -o '^\s*interface:.*@[0-9]*' /etc/unbound/unbound.conf | sed 's!.*@!!;s!\s*!!g' | head -n1)

export NGINX_CLOUDFLARE_CONF='/etc/nginx/cloudflare.conf'
export NGINX_ALLOWLIST_CONF='/etc/nginx/allowlist.conf'
