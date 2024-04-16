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

function umount_root_partition_recursively() {
    umount --lazy /mnt/gentoo/dev{/shm,/pts,} || :
    umount --recursive /mnt/gentoo || :
    umount /mnt/gentoo || :
}

function enable_log() {
    touch "$1"
    chown root:root "$1"
    chmod 600 "$1"
    exec &> >(tee -a >(sed "s/^/$(date +'%Y-%m-%d %H:%M:%S') /" >> "$1"))
}

function log() {
    logger "gentoo-vps-box: $1"
}

script_dir=$(realpath "$(dirname "$0")")
cd "${script_dir}"

if [ "$(id -u)" != "0" ] ; then
    echo 'You need to be root'
    exit 1
fi

if [ "$(uname -m)" = "x86_64" ] ; then
    arch="amd64"
else
    echo 'unsupported CPU architecture'
    exit 1
fi

which chroot
which gpg
which rsync
which sha256sum
which tar
which wget
which xz

source ./02-config.sh

wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
ntpd -gq || :

for i in $(fdisk -l | grep 'Linux swap' | awk '{print $1}') ; do
    swapon "$i" || :
done

TARGET_DISK=$(echo "${ROOT_PARTITION}" | sed 's/[0-9]*$//g')

log "target disk: ${TARGET_DISK}"
log "target partition: ${ROOT_PARTITION}"

mkdir -p /mnt/gentoo
umount_root_partition_recursively
umount "${ROOT_PARTITION}" || :
mount "${ROOT_PARTITION}" -o noatime,nodiratime,discard /mnt/gentoo

enable_log "/mnt/gentoo/gentoo-vps-box.log"

log "STARTING INSTALLATION"

cd /mnt/gentoo
if [[ $(find . -maxdepth 1 ! -name '.*' ! -name '.' ! -name 'lost+found' -type d -print -quit) ]] ; then
    log 'Your partition should not contain non-dot directories. Previous installation has failed? You need to remove old system directories first if so.'
    exit 1
fi
cd "${script_dir}"

mkdir -p /mnt/gentoo/gentoo-root/
if [ -d gentoo-root/ ] ; then
    rsync -a gentoo-root/ /mnt/gentoo/gentoo-root/
fi
mkdir -p /mnt/gentoo/etc
cp -v /etc/resolv.conf /mnt/gentoo/etc/

cd /mnt/gentoo

log "stage3"
mirror="https://distfiles.gentoo.org"
stage3_name="stage3-${arch}-hardened-nomultilib-openrc"
stage3_dir="${mirror}/releases/amd64/autobuilds/current-${stage3_name}"
stage3_filename=$(wget -O - "${stage3_dir}/latest-${stage3_name}.txt" | grep -E '^stage3' | awk '{print $1}')
stage3_url="${stage3_dir}/${stage3_filename}"

wget --continue "${stage3_url}"
for i in "${stage3_url}.asc" "${stage3_url}.sha256" "${stage3_url}.DIGESTS" ; do
    wget --continue "$i"
done
gpg --verify "$(basename "${stage3_url}.asc")"
sha256sum --check "$(basename "${stage3_url}.sha256")"

tar xJpf "$(basename "${stage3_url}")" --xattrs-include='*.*' --numeric-owner --checkpoint=10000 --checkpoint-action=echo="stage3 progress %u"

log "stage3 ok"

test -L /dev/shm && {
    rm /dev/shm && mkdir /dev/shm
    mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
    chmod 1777 /dev/shm /run/shm
}

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

log "mounts ok"

repos=$(
    for i in ${WORLD_PACKAGES[@]} ; do
        echo "$i" | sed 's!.*::!!'
    done | sort -u | grep -v '^gentoo$'
) || :

log "entering chroot"

chroot /mnt/gentoo /bin/bash -s << END
#!/usr/bin/env bash

env-update
source /etc/profile

set -xeuo pipefail

$(declare -f log)
$(declare -f maybe_install_oh_my_zsh)
$(declare -f pre_emerge_packages)
$(declare -f post_emerge_packages)

echo "root:${ROOT_PASSWORD}" | chpasswd

log "webrsync"
mkdir -p /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
emerge-webrsync
emerge --update --oneshot sys-apps/portage::gentoo
log "webrsync ok"

emerge app-portage/cpuid2cpuflags::gentoo
rsync --remove-source-files -av /gentoo-root/etc/portage/ /etc/portage/ || :
grep -q CPU_FLAGS_X86 /etc/portage/make.conf || {
    cpu_flags_x86="\$(cpuid2cpuflags | sed 's!.*: !!;s!rdrand!!g')"
    log "setting CPU_FLAGS_X86 to \${cpu_flags_x86}"
    echo >> /etc/portage/make.conf
    echo "CPU_FLAGS_X86=\"\${cpu_flags_x86}\"" >> /etc/portage/make.conf
}

log "migrating from legacy split-usr to merge-usr"
emerge sys-apps/merge-usr::gentoo || :
merge-usr || :
emerge --unmerge sys-apps/merge-usr::gentoo || :
log "migrating from legacy split-usr to merge-usr ok"

eselect profile set "${PORTAGE_PROFILE}"

log "emerging basic packages"
mkdir -p /etc/portage/package.accept_keywords /etc/portage/package.use
grep -q ${KERNEL_SOURCES} /etc/portage/package.accept_keywords/* || echo '${KERNEL_SOURCES} ~*' >> /etc/portage/package.accept_keywords/package.accept_keywords
grep -q ${KERNEL_SOURCES} /etc/portage/package.use/* || echo '${KERNEL_SOURCES} symlink' >> /etc/portage/package.use/package.use
emerge --autounmask-write=n ${KERNEL_SOURCES} dev-vcs/git::gentoo sys-apps/etckeeper::gentoo app-eselect/eselect-repository::gentoo sys-boot/lilo::gentoo
log "emerging basic packages ok"

git config --global user.name "root"
git config --global user.email "root@${VPS_HOSTNAME}"

mv -f /gentoo-root/usr/src/linux/.config /usr/src/linux/ || :
rm -rf /gentoo-root/usr/src/linux
rsync --remove-source-files -av /gentoo-root/ / || :
rm -rf /gentoo-root
locale-gen

cd /etc
etckeeper init
etckeeper commit Initial
cd /

log "migrating to git repo"
eselect repository remove gentoo
eselect repository enable gentoo
portageq repos_config /

rm -rf /var/db/repos/gentoo
emaint sync --repo gentoo
emerge --autounmask-write=n --update --oneshot sys-apps/portage::gentoo
log "migrating to git repo ok"

log "pre emerge"
set +e
pre_emerge_packages
set -e
log "pre emerge ok"

for i in ${repos[@]} ; do
    log "sync repo \$i"
    eselect repository enable \$i
    emaint sync --repo \$i
    log "sync repo \$i ok"
done

log "updating configs"
chmod 720 /home/*/.ssh || :
chmod 600 /home/*/.ssh/id_* || :
chmod 644 /home/*/.ssh/id_*.pub || :
chmod 600 /etc/ssh/*_key || :

[ -e /etc/ssh/sshd_config ] && sed --in-place 's!SSH_PORT_WILL_BE_AUTOMATICALLY_REPLACED!${SSH_PORT}!g' /etc/ssh/sshd_config
[ -e /etc/conf.d/net ] && sed --in-place 's!NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED!${NET_IFACE}!g' /etc/conf.d/net
[ -e /etc/local.d/00-iptables.start ] && sed --in-place 's!SSH_PORT_WILL_BE_AUTOMATICALLY_REPLACED!${SSH_PORT}!g;s!NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED!${NET_IFACE}!g' /etc/local.d/00-iptables.start
[ -e /etc/local.d/01-ssh-antibruteforce.start ] && sed --in-place 's!SSH_PORT_WILL_BE_AUTOMATICALLY_REPLACED!${SSH_PORT}!g;s!NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED!${NET_IFACE}!g' /etc/local.d/01-ssh-antibruteforce.start
[ -e /usr/local/sbin/unban-ip.sh ] && sed --in-place 's!SSH_PORT_WILL_BE_AUTOMATICALLY_REPLACED!${SSH_PORT}!g;s!NET_IFACE_WILL_BE_AUTOMATICALLY_REPLACED!${NET_IFACE}!g' /usr/local/sbin/unban-ip.sh
[ -e /etc/lilo.conf ] && sed --in-place 's!ROOT_PARTITION_WILL_BE_AUTOMATICALLY_REPLACED!${ROOT_PARTITION}!g;s!TARGET_DISK_WILL_BE_AUTOMATICALLY_REPLACED!${TARGET_DISK}!g' /etc/lilo.conf
[ -e /etc/fstab ] && sed --in-place 's!ROOT_PARTITION_WILL_BE_AUTOMATICALLY_REPLACED!${ROOT_PARTITION}!g' /etc/fstab
[ -e /etc/conf.d/hostname ] && sed --in-place 's!HOSTNAME_WILL_BE_AUTOMATICALLY_REPLACED!${VPS_HOSTNAME}!g' /etc/conf.d/hostname

ln -s /etc/init.d/net.lo /etc/init.d/net.${NET_IFACE}
rc-update add net.${NET_IFACE} default

etckeeper commit Update

cd /usr/src/linux
if [ -e .config ] ; then
    make olddefconfig
else
    make defconfig localmodconfig
fi
sed --in-place 's!HOSTNAME_WILL_BE_AUTOMATICALLY_REPLACED!${VPS_HOSTNAME}!g' /usr/src/linux/.config

log "building kernel"
make -j$(nproc) bzImage modules
cp -vf /usr/src/linux/arch/x86_64/boot/bzImage /boot/vmlinuz.old # workaround for lilo
make modules_install install || :
ls -l /boot
cd /

skip_packages_args=()
for i in ${SKIP_PACKAGES[@]} ; do
    skip_packages_args+=( '--exclude' "\$i" )
done

log "emerging @system packages"
emerge --emptytree --autounmask-write=n --keep-going @system \${skip_packages_args[@]} || :

log "workarounding libsodium circular dependencies"
USE=-verify-sig emerge --oneshot dev-libs/libsodium::gentoo || :
emerge --oneshot app-crypt/minisign::gentoo || :
emerge --oneshot --noreplace dev-libs/libsodium::gentoo || :

log "emerging @world packages"
emerge --autounmask-write=n --keep-going --backtrack=300 ${WORLD_PACKAGES[@]} \${skip_packages_args[@]} || FEATURES=noclean emerge --resume || :

log "reemerging possibly failed @world packages one by one twice with --noreplace"
for i in ${WORLD_PACKAGES[@]} ${WORLD_PACKAGES[@]} ; do
    emerge --noreplace --autounmask-write=n --keep-going --backtrack=300 "\$i" \${skip_packages_args[@]} || :
done
log "finished emerging @world packages"

which eix-update && eix-update

log "add user"
useradd --no-create-home --groups "users" --shell "${USER_SHELL}" "${USERNAME}"
for group in ${USER_GROUPS[@]} ; do
    usermod --append --groups "\${group}" "${USERNAME}" || :
done

echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
mkdir -p /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED
mv -f /home/USERNAME_WILL_BE_AUTOMATICALLY_REPLACED "/home/${USERNAME}"
if [ ! -e /home/${USERNAME}/.bash_alias ] ; then
    [ -e /root/.bash_alias ] && cp -v /root/.bash_alias /home/${USERNAME}/.bash_alias
fi
chmod 700 "/home/${USERNAME}"
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

chsh --shell "${ROOT_SHELL}" root

eselect editor set vim || :

for i in ${ADD_TO_DEFAULT_RUNLEVEL[@]} ; do
    rc-update add "\$i" default || :
done

set +e
log "post emerge"
post_emerge_packages
log "post emerge ok"

log "post emerge user"
su - "${USERNAME}" --command='$(declare -f maybe_install_oh_my_zsh) ; $(declare -f post_emerge_packages_user) ; post_emerge_packages_user'
log "post emerge user ok"
set -e

[ -e /root/.zshrc.pre-oh-my-zsh ] && mv -fv /root/.zshrc{.pre-oh-my-zsh,}
[ -e /home/${USERNAME}/.zshrc.pre-oh-my-zsh ] && mv -fv /home/${USERNAME}/.zshrc{.pre-oh-my-zsh,}

rm -v /$(basename "${stage3_url}")*
sync
END

log "unmounting"
umount_root_partition_recursively

log "INSTALLATION SUCCESS! You can reboot now."
