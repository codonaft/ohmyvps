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

function maybe_install_oh_my_zsh() {
  which zsh && {
    oh_my_zsh_install="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    sh -c "$(wget ${oh_my_zsh_install} -O -)"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone --depth=1 https://github.com/popstas/zsh-command-time ~/.oh-my-zsh/custom/plugins/command-time
  }
}

function install_rust_crate() {
  crate="$1"
  echo "installing ${crate}"
  cargo install --force --locked --version "${QUICSSH_ROBUST_VERSION}" "${crate}"
  mv ~/.cargo/bin/${crate} /mnt/usr/local/bin/
}

function sync_all() {
  sync
  echo 3 >/proc/sys/vm/drop_caches
}

script_dir=$(realpath "$(dirname "$0")")
cd "${script_dir}"

echo 'disable sshd'
rc-service --ifstarted sshd stop 2>>/dev/null || :
apk del openssh 2>>/dev/null || :
echo -n >/etc/init.d/openssh || :
chattr +i /etc/init.d/openssh || :

echo 'disabling tiny-cloud'
eject || :
tiny-cloud --disable || :
apk del tiny-cloud-alpine tiny-cloud || :
deluser --remove-home alpine || :

umount -l /mnt/{dev,sys,proc} || :
umount -l /mnt || :

vim config.sh
source config.sh

setup-apkrepos https://dl-cdn.alpinelinux.org/alpine/latest-stable/{main,community} || :
apk add coreutils e2fsprogs gcc musl-dev sfdisk

echo "${ANSWERS}" >.answers.conf
echo "USEROPTS='none'" >>.answers.conf
echo "APKREPOSOPTS='$(cat /etc/apk/repositories)'" >>.answers.conf
echo "INTERFACESOPTS='$(cat /etc/network/interfaces)'" >>.answers.conf

mount | grep "${TARGET_DISK}" >>/dev/null && {
  echo 'target disk is mounted, fixing it'
  disk_file=$(basename "${TARGET_DISK}")
  cp -r /.modloop /root/
  cp -a /media/"${disk_file}"*/apks /root/
  umount /.modloop /media/${disk_file}*
  ln -sf /root/.modloop/modules /lib/modules
  for i in /media/"${disk_file}"*/ ; do
    cp -a /root/apks "$i"
  done
}

mount | grep "${TARGET_DISK}" >>/dev/null && {
  echo "${TARGET_DISK} is still mounted?"
  exit 1
}

root_partition="${TARGET_DISK}1"
[ "${FORMAT_DISK}" == 1 ] && {
  echo 'creating partition table and filesystem'

  [ -e "${root_partition}" ] && read -r major minor < <(stat -c '%Hr %Lr' "${root_partition}")

  for i in "${TARGET_DISK}"?* ; do
    dd if=/dev/zero of=${i} bs=4K count=1K || :
  done
  dd if=/dev/zero of=${TARGET_DISK} bs=4K count=1 || :
  sync_all

  echo 'type=83' | sfdisk "${TARGET_DISK}"
  sync_all

  [ ! -e "${root_partition}" ] && [ -n "${major}" ] && [ -n "${minor}" ] && {
    mknod -m 660 "${root_partition}" b "${major}" "${minor}"
    chown root:disk "${root_partition}"
  }

  mkfs.ext4 -F -O "${MKFS_OPTS}" "${root_partition}"
  fdisk -l
  sync_all
}

# TODO: another disk
# parted /dev/sdb
# mklabel gpt
# mkpart primary ext4 0% 100%
# quit

mount -t ext4 -o "${MOUNT_OPTS}" "${root_partition}" /mnt
setup-alpine -e -f .answers.conf

mount --rbind /dev /mnt/dev
mount --rbind /sys /mnt/sys
mount --rbind /proc /mnt/proc

[ -d alpine-root/ ] && rsync --archive --no-perms --no-group --no-owner --chmod=go-w alpine-root/ /mnt/

sed --in-place 's!^default_kernel_opts="quiet \(.*\)"$!default_kernel_opts="\1 random.trust_cpu=off init_on_free=1 init_on_alloc=1"!g;s!^default=.*$!default=virt!' /mnt/etc/update-extlinux.conf # affects grub as well
sed --in-place "s!^#Port 22!Port ${SSH_PORT}!;s!^#PasswordAuthentication yes!PasswordAuthentication no!;s!^AllowTcpForwarding no!AllowTcpForwarding yes!" /mnt/etc/ssh/sshd_config
[ "${SSH_ALLOW_TCP}" = '0' ] && sed --in-place 's!^#ListenAddress 0\.0\.0\.0!ListenAddress 127.0.0.1!;s!^#ListenAddress ::!ListenAddress ::1!' /mnt/etc/ssh/sshd_config
sed --in-place "s!\s*ext4\s*rw,relatime\s*!\text4\t${MOUNT_OPTS} !" /mnt/etc/fstab || :

echo "entering chroot"
chroot /mnt /bin/bash -s <<END
#!/usr/bin/env bash

set -xeuo pipefail

$(declare -f sync_all)

mkdir -p /coredumps
chmod 00440 /etc/sudoers
chmod 00640 /etc/ssh/sshd_config
chmod 00700 /coredumps
chown root:wheel /etc/ssh/sshd_config

source /etc/profile.d/99local.sh 2>>/dev/null || :

echo "installing packages"
apk del doas linux-lts openssh-server-pam syslinux || :
apk add alpine-sdk bash etckeeper git grep grub grub-bios libcap linux-virt musl-dev procps python3 shadow ${WORLD_PACKAGES[*]}
rm -rf /var/cache/apk/*

#update-extlinux
grub-mkconfig
grub-install ${TARGET_DISK}

rc-update del sshd default || :
for i in ${ADD_TO_DEFAULT_RUNLEVEL[@]} ; do
  rc-update add "\$i" default || :
done

which vim && ln -sf /usr/bin/vim /usr/local/bin/vi

touch \${LOCAL_BANLIST} \${DNS_BANLIST} \${SSH_ALLOWLIST}
for i in ${SSH_ALLOWED_IPS[@]} ; do
  echo "\$i" >>\${SSH_ALLOWLIST}
done

echo "setting up users"
chmod 00700 /root
setup-user -a -g abuild,audio,video,netdev -k "${USER_SSH_KEY}" -f "${USERNAME}" "${USERNAME}"
[ "${ENABLE_PASSWORDLESS_TTY_ROOT_LOGIN}" == 0 ] && usermod -p '*' root
usermod -p '*' "${USERNAME}"

echo "setting podman stuff"
for i in /etc/sub{u,g}id ; do
  echo "${USERNAME}:100000:65536" >"\$i"
done

echo "changing shells"
chsh --shell "${ROOT_SHELL}" root
chsh --shell "${ROOT_SHELL}" "${USERNAME}"

echo "setting up home dir"
mkdir -p /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED
mv -f /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED/{*,.*} "/home/${USERNAME}/"
[ ! -e /home/${USERNAME}/.bash_alias ] && [ -e /root/.bash_alias ] && cp -v /root/.bash_alias /home/${USERNAME}/.bash_alias
rm -rf /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED
chmod 00700 "/home/${USERNAME}"
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

echo 'installing oh-my-zsh'
$(declare -f maybe_install_oh_my_zsh)
maybe_install_oh_my_zsh
su - "${USERNAME}" -c '$(declare -f maybe_install_oh_my_zsh) ; maybe_install_oh_my_zsh'
[ -e /root/.zshrc.pre-oh-my-zsh ] && mv -fv /root/.zshrc{.pre-oh-my-zsh,}
[ -e /home/${USERNAME}/.zshrc.pre-oh-my-zsh ] && mv -fv /home/${USERNAME}/.zshrc{.pre-oh-my-zsh,}

echo 'update mount points'
mkdir -p -m 00000 /root/tmp /home/${USERNAME}/tmp
echo 'tmpfs /root/tmp tmpfs nosuid,nodev,mode=1700,uid=0,gid=0,size=128M 0 0' >>/etc/fstab
echo 'tmpfs /home/${USERNAME}/tmp tmpfs nosuid,nodev,mode=1700,uid=1000,gid=1000,size=128M 0 0' >>/etc/fstab
echo 'proc /proc proc defaults,hidepid=invisible 0 0' >>/etc/fstab

[ -e /usr/sbin/unbound ] && {
  mkdir -m 00700 -p /etc/unbound/var
  chown unbound:root /etc/unbound/var
  sudo -u unbound unbound-anchor -v -a /etc/unbound/var/root.key || :
}

[ -e /usr/sbin/nginx ] && {
  touch /var/lib/nginx/logs/{access,error}.log
  chown nginx:nginx /var/lib/nginx/logs/{access,error}.log
  mkdir -m 00500 -p /etc/nginx/ssl -p /etc/nginx/ssl/selfsigned
  wget -qO /etc/nginx/ssl/dh2048.pem https://ssl-config.mozilla.org/ffdhe2048.txt
  echo '2ef7758563185ad0dc1dbc38ab3a91647701e3ebee344fcf86b52e643bacb721  /etc/nginx/ssl/dh2048.pem' | sha256sum -c

  openssl genpkey -algorithm ed25519 -out /etc/nginx/ssl/selfsigned/example.com.key
  openssl req -x509 -nodes -days 36500 \
    -key /etc/nginx/ssl/selfsigned/example.com.key \
    -out /etc/nginx/ssl/selfsigned/example.com.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=example.com"

  chmod 00400 /etc/nginx/ssl/dh2048.pem /etc/nginx/ssl/selfsigned/*
  chown -R nginx:nginx /etc/nginx/ssl /etc/nginx/ssl/selfsigned

  which certbot && {
    echo 'setting up certbot'

    setup-user -f certbot certbot
    chmod 00700 /home/certbot
    chown -R certbot:certbot /home/certbot

    mkdir -m 00750 -p /var/www/certbot/.well-known/acme-challenge
    chown certbot:nginx /var/www/certbot/.well-known/acme-challenge

    /etc/init.d/nginx checkconfig
  }
}

[ -e /etc/i2pd ] && {
  chown i2pd:i2pd /var/lib/i2pd || :
  chmod go-rx /var/lib/i2pd || :
}

echo 'setting up etckeeper'
git config --global user.name "root"
git config --global user.email "root@${VPS_HOSTNAME}"

rm -fv /etc/ssh/ssh_host_*

echo 'nameserver 127.0.0.1' >/etc/resolv.conf || :
for i in /etc/conf.d/{coredns,local,nginx} /etc/resolv.conf /etc/update-extlinux.conf /root/.config/htop/htoprc ; do
  chattr +i \$i || :
done

cd /etc
rm -f motd || :
etckeeper init || :
etckeeper commit Initial || :
cd /

sync_all
cat /etc/alpine-release || :
END

cp /etc/apk/repositories /mnt/etc/apk/repositories
chattr +i /mnt/etc/apk/repositories

echo 'installing rust'
apk add --update --no-cache rustup
rustup-init -y --profile minimal --default-toolchain "${RUST_VERSION}" --target x86_64-unknown-linux-musl
source ~/.cargo/env
rustc --print target-cpus | grep native | sed 's/.* (currently //;s/)\.//' >/mnt/etc/target-cpu
export CFLAGS='-O3 -pipe -march=native -mno-rdrnd -fPIE -fPIC -fstack-protector-all -fstack-clash-protection --param ssp-buffer-size=4 -Wstack-protector -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fdiagnostics-color=always'
export CXXFLAGS="${CFLAGS}"
export FCFLAGS="${CFLAGS}"
export FFLAGS="${CFLAGS}"
export LDFLAGS='-Wl,-z,now -Wl,-z,relro'
export RUSTFLAGS='-C target-cpu=native -C force-frame-pointers=y'

install_rust_crate quicssh-rs-robust

sync_all

umount -l /mnt/{dev,sys,proc} || :
umount -l /mnt || :

echo 'INSTALLATION SUCCESS! You can reboot now.'
