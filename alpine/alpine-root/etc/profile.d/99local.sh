export RUSTFLAGS="-C target-cpu=native -C force-frame-pointers=y"
export CFLAGS="-O2 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always"
export CXXFLAGS="-O2 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always"
export FCFLAGS="-O2 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always"
export FFLAGS="-O2 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always"
export LDFLAGS="-Wl,-z,now -Wl,-z,relro"
#export MAKEOPTS="-j16 -l16"

export EDITOR="vim"

export WHEEL_UID='1000'
export ADMIN_GROUP='wheel'

export LOCAL_BANLIST="/var/tmp/local-banlist.txt"
export SSH_BANLIST="/etc/ssh/banlist.txt"
export SSH_ALLOWLIST="/etc/ssh/allowlist.txt"

export SYSLOG="/tmp/messages"

export SSH_PORT=$( ( grep -E '^Port [0-9]*$' /etc/ssh/sshd_config || echo 'Port 22' ) | awk '{print $2}' )

export NGINX_CLOUDFLARE_CONF="/etc/nginx/cloudflare.conf"
export NGINX_ALLOWLIST_CONF="/etc/nginx/allowlist.conf"

export NET_IFACE=$(grep '^auto e' /etc/network/interfaces | awk '{print $2}' | head -n1)
export NET_IPV4=$(grep -A 3 '^auto e' /etc/network/interfaces | grep address | head -n1 | awk '{print $2}' | grepcidr -e '0.0.0.0/0')
