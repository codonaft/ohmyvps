# ohmyvps: Preconfigured Hardended GNU/Linux for VPS
- currently `x86_64` is the only supported
- `nginx` runs completely rootless
- firewall disallows all incoming connections, besides `ssh`, `http` and `https` by default
- `ssh`
    - default `sshd` configuration disallows password authentication
    - manual `ssh` port by default
    - allow-list for incoming `ssh` connections
        - alternatively, firewall autobans those who failed to login
- designed for `tmux` + `vim` users.

## Installation
- [Alpine Linux](alpine/README.md)
- [Gentoo Hardened](gentoo/README.md) (not actively maintained at the moment)

## Support
I'm currently investing [all my time](https://codonaft.com/why) in personal projects and no longer making any income from proprietary commercial projects owned by third-party businesses.

If you found this repo useful and you want to support me, please
- ⭐ it
- check [here](https://codonaft.com/sponsor)

Thank you for your support! ❤️ (◕‿◕)

## License
MIT
