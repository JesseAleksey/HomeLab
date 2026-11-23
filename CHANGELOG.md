# Changelog

Dates are local time (US Central). Commit timestamps in git are UTC because the server's time zone is `Etc/UTC`.

## 2026-11-23

- Reorganised the docs: the README is now a short overview, and the details live in `docs/01`–`07`, `docs/troubleshooting.md` and this changelog.
- **Applied the read-only NAS mount on the host:** `/etc/fstab` changed from `defaults,_netdev` to `ro,_netdev` (backup `/etc/fstab.bak-2026-11-23`). The docs had said `ro`, but the live mount was `rw`. (`b4867a5`)
- Added health check 2b: fails if `/mnt/media` isn't mounted read-only. (`c96c52f`)

## 2026-11-22

Built the homelab: Ubuntu Server on the OptiPlex 7010, Docker, the Synology SHR pool and NFS export, AdGuard Home and Jellyfin.

- Added `docker-compose.yml` for AdGuard Home and Jellyfin, with host networking. (`fd13a9b`)
- Added `CLAUDE.md` with the hardware, network, services and rules. (`f191e55`)
- Added a read-only `health-check.sh` for the containers, NAS mount, DNS, Jellyfin and disk. (`5c88a2b`)
- Pinned images to their running digests: AdGuard Home `v1.0.0`, Jellyfin `12.4`. (`500f172`)
- Rewrote the README to match the actual setup. (`527d616`)
- Documented the NAS media as read-only at host and container level. The host part wasn't applied until 2026-11-23. (`a00d69f`)

## 2026-11-20

- Created the `JesseAleksey/HomeLab` repo on GitHub with a README and `.gitignore`. (`849495b`, `d767d29`)
