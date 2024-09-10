# Gentoo
For experts only. This script doesn't precisely follow Gentoo Handbook, use at your own risk.

- uses `vanilla-sources` by default
- uses `cpuid2cpuflags` if `CPU_FLAGS_X86` are not manually edited
- none of the files in `gentoo-root/` are strictly required
    - before installation you can remove entire directory instead (although this wasn't heavily tested) and do manual configuration before/after installation.

## Prepare
1. Login to your VPS control panel, go to remote access/VNC page.

2. Boot VPS instance from any Ubuntu ISO image. Go to step 3 on success.

2.1. If your VPS doesn't support direct boot from `.iso`, then boot into preinstalled Ubuntu and use netboot:

```bash
sh -c "$(curl -L https://omv.codonaft.com)"
```

Choose `2` → `reboot` → wait for boot menu →  `Bootable ISO Image: netboot.xyz` → configure network (if there's no DHCP) → `Linux Network Installs (64-bit)` → `Ubuntu` → latest LTS version → `Rescue Mode`.

If this method doesn't work for you—try other ways to boot the [netboot](https://github.com/netbootxyz/netboot.xyz#bootloader-downloads).

3. Before installing, you need a disk with `dos` partition table and at least one ext4 partition. *Optionally* you can create a swap partition as well (it will be activated automatically). [Something](https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Creating_a_new_disklabel_/_removing_all_partitions) like:

```bash
sgdisk --zap-all /dev/vda
echo 'type=83' | sfdisk /dev/vda
mkfs.ext4 -O orphan_file,fast_commit /dev/vda1
```

You don't necessarily need a completely empty root partition to start installing, however your partition should not contain non-dot directories (other than `lost+found`).

## Usage
1. `Enter` to configure the system. Copy ssh keys to `gentoo-root/{home/*/.ssh,etc/ssh/}` if necessary

2. `C-a 2` → `Enter` to install the system

## Troubleshooting
Failure? Make changes and restart `./03-install.sh`

Sudden reboot/etc.? Check `/mnt/gentoo/ohmyvps.log`
