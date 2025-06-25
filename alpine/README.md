# Alpine

## Installation

### 1. Login to your VPS control panel → go to remote access/VNC page.

### 2. Boot VPS instance from Alpine Linux `.iso` → configure network:

```bash
setup-interfaces
setup-dns 9.9.9.9 1.1.1.1
/etc/init.d/networking start
```

Go to [step 3](#3-install) on success.

#### 2.1. If your VPS doesn't support direct boot from `.iso`
Boot into preinstalled Ubuntu and use it to boot from Alpine installation `.iso`:

```bash
sh -c "$(curl -L https://omv.codonaft.com)"
```

or

```bash
sh -c "$(wget -O - https://omv.codonaft.com)"
```

Choose `2` → login as `root` → configure network again.

### 3. Install
```bash
sh -c "$(wget -O - https://omv.codonaft.com)"
```

Choose `1`. You will see vim with setup configuration file.

You don't necessarily need a completely empty root partition to start installing.
You'll need a disk with `dos` partition table and with a **single** primary ext4 partition.
Set `FORMAT_DISK='1'` to create it.

None of the files in `alpine-root/` are strictly required, you can remove entire directory using other tty on this step (although this wasn't heavily tested) and do manual configuration before/after installation.

## Troubleshooting
Failure? Make changes and restart `*ohmyvps*/alpine/install.sh`
