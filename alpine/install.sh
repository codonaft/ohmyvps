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

script_dir=$(realpath "$(dirname "$0")")
cd "${script_dir}"

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

echo "${ANSWERS}" > .answers.conf
echo "USEROPTS='none'" >> .answers.conf
echo "APKREPOSOPTS='$(cat /etc/apk/repositories)'" >> .answers.conf
echo "INTERFACESOPTS='$(cat /etc/network/interfaces)'" >> .answers.conf

mount | grep "${TARGET_DISK}" >>/dev/null && {
  echo 'target disk is mounted, fixing it'
  disk_file=$(basename "${TARGET_DISK}")
  cp -r /.modloop /root/
  cp -a /media/${disk_file}*/apks /root/
  umount /.modloop /media/${disk_file}*
  ln -sf /root/.modloop/modules /lib/modules
  for i in /media/${disk_file}*/ ; do
    cp -a /root/apks "$i"
  done
}

mount | grep "${TARGET_DISK}" >>/dev/null && {
  echo "${TARGET_DISK} is still mounted?"
  exit 1
}

root_partition="${TARGET_DISK}1"
apk add sfdisk sgdisk e2fsprogs
[ "${FORMAT_DISK}" == 1 ] && {
  echo 'creating partition table and filesystem'
  sgdisk --zap-all "${TARGET_DISK}"
  echo 'type=83' | sfdisk "${TARGET_DISK}"
  mkfs.ext4 -F -O "${MKFS_OPTS}" "${root_partition}"
  fdisk -l
  sync
  echo 3 > /proc/sys/vm/drop_caches
}

# TODO: another disk
# parted /dev/sdb
# mklabel gpt
# mkpart primary ext4 0% 100%
# quit

mount -t ext4 -o "${MOUNT_OPTS}" "${root_partition}" /mnt
/etc/init.d/networking stop || :
setup-alpine -e -f .answers.conf

mount --rbind /dev /mnt/dev
mount --rbind /sys /mnt/sys
mount --rbind /proc /mnt/proc

if [ -d alpine-root/ ] ; then
  rsync --archive --no-perms --no-group --no-owner --chmod=go-w alpine-root/ /mnt/
fi

sed --in-place 's!^default_kernel_opts="quiet \(.*\)"$!default_kernel_opts="\1 random.trust_cpu=off"!g;s!^default=.*$!default=virt!' /mnt/etc/update-extlinux.conf # affects grub as well
sed --in-place "s!^#Port 22!Port ${SSH_PORT}!;s!^#PasswordAuthentication yes!PasswordAuthentication no!;s!^AllowTcpForwarding no!AllowTcpForwarding yes!" /mnt/etc/ssh/sshd_config
sed --in-place "/^\/.*/d;s!^#http!http!;s!^http:!https:!" /mnt/etc/apk/repositories || :
sed --in-place "s!\s*ext4\s*rw,relatime\s*!\text4\t${MOUNT_OPTS} !" /mnt/etc/fstab || :

mkdir -p /mnt/coredumps
chmod 00700 /mnt/coredumps
chmod 00440 /mnt/etc/sudoers || :

echo "entering chroot"
chroot /mnt /bin/bash -s << END
#!/usr/bin/env bash

set -xeuo pipefail

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

echo -n > /etc/ssh/allowlist.txt
for i in ${SSH_ALLOWED_IPS[@]} ; do
  echo "\$i" >> /etc/ssh/allowlist.txt
done

echo "setting up users"
chmod 00700 /root
setup-user -a -g abuild,audio,video,netdev -k "${USER_SSH_KEY}" -f "${USERNAME}" "${USERNAME}"
[ "${ENABLE_PASSWORDLESS_TTY_ROOT_LOGIN}" == 0 ] && usermod -p '*' root
usermod -p '*' "${USERNAME}"

echo "setting podman stuff"
for i in /etc/sub{u,g}id ; do
  echo "${USERNAME}:100000:65536" > "\$i"
done

echo "changing shells"
chsh --shell "${ROOT_SHELL}" root
chsh --shell "${ROOT_SHELL}" "${USERNAME}"

echo "setting up home dir"
mkdir -p /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED
mv -f /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED/{*,.*} "/home/${USERNAME}/"
if [ ! -e /home/${USERNAME}/.bash_alias ] ; then
  [ -e /root/.bash_alias ] && cp -v /root/.bash_alias /home/${USERNAME}/.bash_alias
fi
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
echo 'tmpfs /root/tmp tmpfs nosuid,nodev,mode=1700,uid=0,gid=0,size=128M 0 0' >> /etc/fstab
echo 'tmpfs /home/${USERNAME}/tmp tmpfs nosuid,nodev,mode=1700,uid=1000,gid=1000,size=128M 0 0' >> /etc/fstab
echo 'proc /proc proc defaults,hidepid=invisible 0 0' >> /etc/fstab

[ -e /usr/sbin/nginx ] && {
  touch /var/lib/nginx/logs/{access,error}.log
  chown nginx:nginx /var/lib/nginx/logs/{access,error}.log
  mkdir -m 00500 -p /etc/nginx/ssl -p /etc/nginx/ssl/selfsigned
  wget -qO /etc/nginx/ssl/dh2048.pem https://ssl-config.mozilla.org/ffdhe2048.txt

  openssl genpkey -algorithm ed25519 -out /etc/nginx/ssl/selfsigned/example.com.key
  openssl req -x509 -nodes -days 365 \
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
sort -u < /etc/apk/repositories | grep -v 'http://' > /etc/apk/repositories || :

cd /etc
rm -f motd
etckeeper init
etckeeper commit Initial
cd /

chattr +i /etc/update-extlinux.conf
[ -e /etc/conf.d/nginx ] && chattr +i /etc/conf.d/nginx

echo 'source /etc/profile.d/99local.sh' > /etc/conf.d/local
chattr +i /etc/conf.d/local

sync
echo 3 > /proc/sys/vm/drop_caches
cat /etc/alpine-release || :
END

umount -l /mnt/{dev,sys,proc} || :
umount -l /mnt || :

echo "INSTALLATION SUCCESS! You can reboot now."
