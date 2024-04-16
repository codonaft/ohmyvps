export ROOT_PARTITION='/dev/vda1'

export NET_IFACE='UNDETECTED_PLEASE_FILL_OUT'
export SSH_PORT='666'
export VPS_HOSTNAME='vps'

export ROOT_PASSWORD='r00tP4ssw0rd'
export ROOT_SHELL='/bin/zsh'

export USERNAME='vpsuser'
export USER_PASSWORD='us3rP4ssw0rd'
export USER_GROUPS=( wheel docker portage ) # user will be added to "users" group automatically, nonexistent groups will be ignored
export USER_SHELL='/bin/zsh'

export PORTAGE_PROFILE='default/linux/amd64/23.0/no-multilib/hardened'

export KERNEL_SOURCES='sys-kernel/vanilla-sources::gentoo'

export WORLD_PACKAGES=(
    #app-admin/i2pd-tools::guru # NOTE: external repos will be automatically added
    app-admin/logrotate::gentoo
    app-admin/sudo::gentoo
    app-admin/syslog-ng::gentoo
    #app-antivirus/clamav::gentoo
    #app-forensics/chkrootkit::gentoo
    #app-misc/resolve-march-native::gentoo
    app-misc/srm::gentoo
    #app-arch/p7zip::gentoo
    #app-containers/docker::gentoo
    app-containers/podman::gentoo
    #app-crypt/mkp224o::gentoo
    app-editors/vim::gentoo
    app-misc/colordiff::gentoo
    app-misc/tmux::gentoo
    app-portage/eix::gentoo
    app-portage/emlop::gentoo
    app-portage/gentoolkit::gentoo
    app-shells/zsh::gentoo
    #dev-debug/gdb::gentoo
    dev-java/openjdk-bin::gentoo
    dev-lang/ruby::gentoo
    net-analyzer/mtr::gentoo
    net-analyzer/netcat::gentoo
    net-analyzer/netselect::gentoo
    #net-analyzer/nmap::gentoo
    net-analyzer/traceroute::gentoo
    net-dns/bind-tools::gentoo
    net-dns/dnscrypt-proxy::gentoo
    net-firewall/iptables::gentoo
    #net-firewall/ufw::gentoo
    #net-libs/nodejs::gentoo
    net-misc/autossh::gentoo
    net-misc/ntp::gentoo
    #net-misc/socat::gentoo
    net-misc/telnet-bsd::gentoo
    #net-p2p/rtorrent::gentoo
    #net-proxy/tinyproxy::gentoo
    #net-vpn/i2pd::gentoo
    #net-vpn/tor::gentoo
    sys-apps/hdparm::gentoo
    #sys-devel/distcc::gentoo
    sys-fs/ncdu::gentoo
    sys-process/cronie::gentoo
    sys-process/htop::gentoo
    sys-process/iotop::gentoo
    #www-servers/nginx::gentoo
)

export SKIP_PACKAGES=(
    sys-devel/gcc # requires lots of memory
)

export ADD_TO_DEFAULT_RUNLEVEL=(
    acpid
    autofs
    clamd
    clamonacc
    cronie
    dnscrypt-proxy
    docker
    freshclam
    local
    netmount
    ntp-client
    rpc.statd
    syslog-ng
)

function maybe_install_oh_my_zsh() {
    which zsh && {
        oh_my_zsh_install="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
        highlighting="git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        command_time="git clone --depth=1 https://github.com/popstas/zsh-command-time ~/.oh-my-zsh/custom/plugins/command-time"
        sh -c "$(wget ${oh_my_zsh_install} -O -) ; ${highlighting} ; ${command_time}"
    }
}

function pre_emerge_packages() {
    # Run any commands before emerging system/world packages and before user creation, for instance:
    eselect repository add alopatindev-overlay git https://github.com/alopatindev/gentoo-overlay-alopatindev
    emaint sync -r alopatindev-overlay
    ls -l /var/db/repos
    emerge --nodeps --oneshot dev-libs/openssl::alopatindev-overlay # disable rdrand
}

function post_emerge_packages() {
    mkdir -p /coredumps
    chmod 700 /coredumps

    which netselect && which nslookup && [ -e /etc/ntp.conf ] && {
        # resolve IPs for ntp as reserve source of correct time.
        # why? sometimes dnscrypt-proxy fails, this causes ntp failure, time might desynchronize,
        # then dnscrypt never restores because it seems it needs actual time.
        ntp_server_ips=()
        for ntp_server in $(echo pool.ntp.org ; grep '^server ' /etc/ntp.conf | awk '{print $2}') ; do
            ntp_server_ips+=( $(nslookup "${ntp_server}" | grep Address: | awk '{print $2}' | grep -v '#') )
        done
        fastest_ntp_server_ips=$(netselect -s 5 ${ntp_server_ips[@]} | awk '{print $2}' | tr '\n' ' ')

        hourly="/etc/cron.hourly"
        mkdir -p "${hourly}"
        cron_script="${hourly}/ntpdate"
        echo '#!/usr/bin/env bash' > "${cron_script}"
        echo '' >> "${cron_script}"
        echo "ntpdate -s -t60 ${fastest_ntp_server_ips}&& hwclock --systohc && logger 'time has been updated' || /etc/init.d/ntp-client restart" >> "${cron_script}"
        chmod +x "${cron_script}"
    }

    maybe_install_oh_my_zsh

    # touch /forcefsck
    # chattr +i /forcefsck
    #
    # echo 'nameserver 127.0.0.1' > /etc/resolv.conf
    # chattr +i /etc/resolv.conf
}

# this will run as USERNAME
function post_emerge_packages_user() {
    git config --global user.name "${USERNAME}"
    git config --global user.email "${USERNAME}@${VPS_HOSTNAME}"
    maybe_install_oh_my_zsh
}
