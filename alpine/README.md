# Alpine

## Installation

1. Login to your VPS control panel → go to remote access/VNC page

2. Boot VPS instance from preinstalled Alpine Linux or Ubuntu

3. Configure network

In particular, on Alpine Linux:

```bash
setup-interfaces
setup-dns 9.9.9.9 1.1.1.2
/etc/init.d/networking start
```

4. Install

```bash
sh <(wget -O - https://omv.codonaft.com)
```

or

```bash
sh <(curl -L https://omv.codonaft.com)
```

Choose `1`. You will see vim with setup configuration file.

## Note

You don't necessarily need a completely empty root partition to start installing.
You'll need a disk with `dos` partition table and with a **single** primary ext4 partition.
`FORMAT_DISK='1'` creates it by default.

None of the files in `alpine-root/` are strictly required, you can remove entire directory using other tty on this step (although this wasn't heavily tested) and do manual configuration before/after installation.

## Troubleshooting
Failure? Make changes and restart `/ohmyvps/install.sh`.
