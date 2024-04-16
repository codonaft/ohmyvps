# Install pre-configured Gentoo on KVM VPS
For experts only. This script doesn't precisely follow Gentoo Handbook, use at your own risk.

- currently `amd64` is the only supported
- uses `vanilla-sources` by default
- `ssh`
    - default `sshd` configuration disallows password authentication
    - manual `ssh` port by default
    - firewall disallows all incoming connections, besides `ssh` by default
    - firewall autobans those who failed to login
- uses `cpuid2cpuflags` if `CPU_FLAGS_X86` are not manually edited
- designed for `tmux` + `vim` users
- none of the files in `gentoo-root/` are strictly required
    - before installation you can remove entire directory instead (although this wasn't heavily tested) and do manual configuration before/after installation.

## Prepare
1. Login to your VPS control panel, go to remote access/VNC page.

2. Boot KVM VPS instance from any comfortable `.iso`, ideally with `git`, `vim`, `tmux` and `htop` preinstalled (usually Ubuntu Server LTS images are okay).

If your VPS doesn't support direct boot from `.iso`, then try [grub-imageboot + netboot](https://netboot.xyz/docs/booting/grub#on-debianubuntu) from preinstalled Ubuntu. In this case make sure you've set `GRUB_TIMEOUT=30` and `GRUB_TIMEOUT_STYLE=menu` in the `/etc/default/grub*` before running `update-grub2`.

3. Setup temporary [network](00-setup-network.sh) whatever way you like.

4. Before installing, you [need](https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation#Creating_a_new_disklabel_/_removing_all_partitions) dos partition table and at least one ext4 partition. *Optionally* you can create a swap partition as well (it will be activated automatically).

You don't necessarily need a completely empty root partition to start installing, however your partition should not contain non-dot directories (other than `lost+found`).

## Usage
1. Download
```bash
cd ~

git clone --depth=1 https://github.com/codonaft/gentoo-vps-box

# Alternatively:
#   wget https://api.github.com/repos/codonaft/gentoo-vps-box/tarball -O - | tar xzf - && mv codonaft-gentoo-vps-box* gentoo-vps-box
# or
#   curl -sS https://api.github.com/repos/codonaft/gentoo-vps-box/tarball -O - | tar xzf - && mv codonaft-gentoo-vps-box* gentoo-vps-box
```

2. Run preconfigured tmux
```bash
gentoo-vps-box/01-run-tmux.sh
```

3. `Enter` to configure the system. Copy ssh keys to `gentoo-root/{home/*/.ssh,etc/ssh/}` if necessary

4. `C-a 2` → `Enter` to install the system

## Troubleshooting
Failure? Make changes and restart `./03-install.sh`

Sudden reboot/etc.? Check `/mnt/gentoo/gentoo-vps-box.log`

## Support
I'm currently investing [all my time](https://codonaft.com/why) in personal projects and no longer making any income from proprietary commercial projects owned by third-party businesses.

If you found this repo useful and you want to support me, please
- ⭐ it
- check [here](https://codonaft.com/sponsor)

Thank you for your support! ❤️ (◕‿◕)

## License
MIT
