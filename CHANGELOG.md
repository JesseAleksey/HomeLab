# Changelog

Dates are local time (US Central). The server's time zone was `Etc/UTC` until 2026-11-23, so commits before then show UTC; later commits show Central time.

## 2026-11-23

- **README:** added a Skills demonstrated line under Tools, embedded the AdGuard dashboard screenshot under the headline numbers, and updated those numbers to match the screenshot (65,834 queries from 32 devices, 10,999 blocked (17%), 85 ms average). `docs/05` keeps the earlier 64,219 figures.
- **Repo cleanup:** stopped tracking the AI assistant's notes file (CLAUDE.md), kept on the server and now in `.gitignore`; renamed `docs/07` to [Version control and tools](docs/07-version-control-and-tools.md) with a short note on how I used an AI assistant; rule references in `docs/05` and `docs/troubleshooting.md` now state the rule itself; added a Tools line to the README.
- **Doc accuracy fixes:**
  - Port 53 is now described as a preventive step: AdGuard never hit `bind: address already in use`, because I disabled the `systemd-resolved` stub listener before starting it. (`docs/05`, `docs/troubleshooting.md`)
  - `docs/07` Steps show how the repo was actually set up (`git init -b main` in the existing `~/homelab`, add the remote, `git pull origin main`), plus the real no-reply commit email, with `docs/screenshots/*.png` added to "What's in git".
  - `docs/04` lists the exact fstab commands run.
  - The 220 ms ping is no longer tied to wired Ethernet; Ethernet is planned for reliability. (`docs/01`)
  - The eero fallback is named "ISP DNS (Default)" everywhere. (`docs/03`, `docs/troubleshooting.md`)
  - The SSD model is `SDSSDA120G`. (`docs/01`)
  - `docs/02` now follows the template: Time zone is step 5 and key-only SSH login sits under Next steps.
  - Added a blank line in `.gitignore`.
- **AdGuard dashboard screenshot:** added the cropped version (stat cards only, no client IPs) as `docs/screenshots/adguard-dashboard.png` and embedded it under Verification in `docs/05`.
- **Screenshots:** added 9 verification screenshots in `docs/screenshots/` and embedded them under Verification in `docs/03` (docker ps, health check), `docs/04` (storage pool, NFS permissions), `docs/05` (nslookup, blocklists, upstream DNS, general settings) and `docs/06` (libraries). Left out the AdGuard dashboard screenshot because it showed top clients by IP; a cropped version will replace it later.
- **Synology:** documented the MAC (`00:11:32:44:23:E4`), DSM 7.1.1-42962 Update 9, the static IP `192.168.4.10` set on the Synology to match the eero reservation, and the full NFS rule confirmed in DSM (read only, map all users to admin, async, non-privileged ports and cross-mount denied). (`docs/01`, `docs/04`)
- **AdGuard DNS settings:** parallel requests to Cloudflare and Quad9 DoH, fallback `1.1.1.1`/`9.9.9.9`, IPv4 and IPv6 bootstrap, private reverse DNS on, 10 s upstream timeout. (`docs/05`)
- **AdGuard general settings:** browsing security on (replacing eero Secure), parental control and safe search off, query log rotation cut from 90 to 30 days. (`docs/05`)
- **AdGuard results:** 64,219 queries from 32 devices in 24 hours, 10,776 blocked (16.8%), 84 ms average. Added to `docs/05` and the README.
- **AdGuard password reset:** forgot the admin password and hit the HTTP 429 login lockout; reset the bcrypt hash in `AdGuardHome.yaml` with a locally generated `htpasswd -B -C 10` hash (brief DNS outage during the restart). (`docs/05`)
- **Time zone:** set the server to `America/Chicago`; logs and commits now show local time. (`docs/02`, `docs/07`)
- **SSH:** replaced an exposed private key with a new ed25519 key and overwrote `authorized_keys`. Key-only login is planned but not done: `50-cloud-init.conf` still enables password login and overrides `sshd_config`. (`docs/02`)
- **Jellyfin:** the daily 3 AM library scan is scheduled. Hardware transcoding test and client apps still TODO. (`docs/06`)
- Added the new problems to `docs/troubleshooting.md`.
- Replaced the "What I learned" placeholders in `docs/01`–`07` with my own notes.
- Filled in doc TODOs: the 220 ms ping spike, the fake-capacity USB stick and the first SSH disconnect, the planned use of `/volume1/homelab-backup` for nightly backups (future `docs/08-backups.md`), the planned off-NAS media backup, the eero fallback DNS steps, the daily library scan and the time zone plan.
- Reorganised the docs: the README is now a short overview, and the details live in `docs/01`–`07`, `docs/troubleshooting.md` and this changelog.
- **Applied the read-only NAS mount on the host:** `/etc/fstab` changed from `defaults,_netdev` to `ro,_netdev` (backup `/etc/fstab.bak-2026-11-23`). The docs had said `ro`, but the live mount was `rw`. (`b4867a5`)
- Added health check 2b: fails if `/mnt/media` isn't mounted read-only. (`c96c52f`)

## 2026-11-22

Built the homelab: Ubuntu Server on the OptiPlex 7010, Docker, the Synology SHR pool and NFS export, AdGuard Home and Jellyfin.

- Added `docker-compose.yml` for AdGuard Home and Jellyfin, with host networking. (`fd13a9b`)
- Added the AI assistant's notes file (CLAUDE.md) with the hardware, network, services and rules. (`f191e55`; kept local and untracked since 2026-11-23)
- Added a read-only `health-check.sh` for the containers, NAS mount, DNS, Jellyfin and disk. (`5c88a2b`)
- Pinned images to their running digests: AdGuard Home `v1.0.0`, Jellyfin `12.4`. (`500f172`)
- Rewrote the README to match the actual setup. (`527d616`)
- Documented the NAS media as read-only at host and container level. The host part wasn't applied until 2026-11-23. (`a00d69f`)

## 2026-11-20

- Created the `JesseAleksey/HomeLab` repo on GitHub with a README and `.gitignore`. (`849495b`, `d767d29`)
