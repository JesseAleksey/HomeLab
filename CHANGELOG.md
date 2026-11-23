# Changelog

Dates are local time (US Central). The server's time zone was `Etc/UTC` until 2026-11-23, so commits before then show UTC; later commits show Central time.

## 2026-11-23

- **Synology:** documented the MAC (`00:11:32:44:23:E4`), DSM 7.1.1-42962 Update 9, the static IP `192.168.4.10` set on the Synology to match the eero reservation, and the full NFS rule confirmed in DSM (read only, map all users to admin, async, non-privileged ports and cross-mount denied). (`docs/01`, `docs/04`)
- **AdGuard DNS settings:** parallel requests to Cloudflare and Quad9 DoH, fallback `1.1.1.1`/`9.9.9.9`, IPv4 and IPv6 bootstrap, private reverse DNS on, 10 s upstream timeout. (`docs/05`)
- **AdGuard general settings:** browsing security on (replacing eero Secure), parental control and safe search off, query log rotation cut from 90 to 30 days. (`docs/05`)
- **AdGuard results:** 64,219 queries from 32 devices in 24 hours, 10,776 blocked (16.8%), 84 ms average. Added to `docs/05` and the README.
- **AdGuard password reset:** forgot the admin password and hit the HTTP 429 login lockout; reset the bcrypt hash in `AdGuardHome.yaml` with a locally generated `htpasswd -B -C 10` hash (brief DNS outage during the restart). (`docs/05`)
- **Time zone:** set the server to `America/Chicago`; logs and commits now show local time. (`docs/02`, `docs/07`)
- **SSH:** replaced an exposed private key with a new ed25519 key and overwrote `authorized_keys`. Key-only login is planned but not done: `50-cloud-init.conf` still enables password login and overrides `sshd_config`. (`docs/02`)
- **Jellyfin:** the daily 3 AM library scan is scheduled. Hardware transcoding test and client apps still TODO. (`docs/06`)
- Added the new problems to `docs/troubleshooting.md`.
- Filled in doc TODOs: the 220 ms ping spike, the fake-capacity USB stick and the first SSH disconnect, the planned use of `/volume1/homelab-backup` for nightly backups (future `docs/08-backups.md`), the planned off-NAS media backup, the eero fallback DNS steps, the daily library scan and the time zone plan.
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
