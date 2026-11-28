# Changelog

Dates are local time (US Central). The server's time zone was `Etc/UTC` until 2026-11-23, so commits before then show UTC; later commits show Central time.

## 2026-11-28

- **Seerr added** as a third container (`seerr`, port 5055, host networking), pinned to `v3.5.2` by digest. Seerr is the merged successor to Jellyseerr and Overseerr. Data lives in `seerr/`, which is git-ignored. Started with `docker compose up -d --no-deps seerr`, so AdGuard and Jellyfin were not restarted. First-run setup done: signed in with the Jellyfin admin account, Movies and Shows libraries enabled, no Radarr/Sonarr yet.
- **Jellyfin plugin repositories:** added JellyBridge (`kinggeorges12/JellyBridge`), Jellyfin Enhanced (`n00bcodr/jellyfin-plugins`, version 12 manifest) and Intro Skipper (`intro-skipper.org`) to `system.xml`, after checking each catalog lists builds for Jellyfin 12.x. Installed JellyBridge `5.2.12.0`, Jellyfin Enhanced `12.17.0.0` and Intro Skipper `12.0.8.0` by unpacking the release zips into `jellyfin/config/plugins/` after verifying each against the MD5 in its catalog; all three load as Active. JellyBridge is pointed at Seerr (`http://localhost:5055`, API key from Seerr, working folder `/config/jellybridge`); its discover library still has to be created from the plugin page.
- **Jellyfin transcoding:** hardware decoding now covers MPEG-2 and VC-1 as well as H.264 (all supported by the HD 2500 over VAAPI); transcode throttling and segment deletion turned on. Backups: `encoding.xml.bak-2026-11-28` and `system.xml.bak-2026-11-28` in `jellyfin/config/config/`. Jellyfin restarted once.
- **AdGuard DNS cache** (changed in the admin UI on 2026-11-27): cache size 4 MB to 32 MB, optimistic caching on. Upstreams unchanged (Cloudflare and Quad9 DoH, parallel); a short trial of plain `1.1.1.1`/`9.9.9.9` caused 10-second timeouts on about 3% of lookups and was reverted.
- **Deco:** firmware updated on all five units (BE11000 `1.0.2` to `1.3.6`, W2400 `1.5.1` to `1.5.2`). DHCP Secondary DNS set to `1.1.1.1` as a fallback, which lets devices bypass AdGuard some of the time; remove it to restore AdGuard-only DNS.
- **SSH:** added a second authorised key for the admin PC (`~/.ssh/authorized_keys`).
- **Download automation stack added** to `docker-compose.yml`, all images pinned by digest: Gluetun (NordVPN) + qBittorrent `5.3.1`, Prowlarr `3.1.0`, Radarr `7.0.3`, Sonarr `4.0.20`, Bazarr `1.6.2`. Only qBittorrent is behind the VPN (it shares gluetun's network); everything else stays on host networking. Each service was started with `docker compose up -d --no-deps <name>`, so AdGuard was never restarted.
  - **New NAS share `data`** (`/volume1/data`, NFS read-write for `192.168.68.81`, map all users to admin), mounted by Docker as the named volume `data` at `/data`. Downloads go to `/data/torrents`, the library to `/data/media`, on one mount so imports are hardlinks. Tested: a file linked from `torrents/` to `media/` shares one inode with link count 2.
  - **Wiring done over the apps' APIs:** Radarr and Sonarr root folders, Prowlarr synced to both, Seerr sending requests to both (HD-1080p profile).
  - **Jellyfin** recreated with `data:/data:ro`; `/data/media/movies` and `/data/media/tv` added to the Movies and Shows libraries next to the existing `/media` paths (backups `options.xml.bak-2026-11-28`).
  - **VPN verified:** with NordVPN service credentials in the git-ignored `vpn.env`, gluetun connects over OpenVPN and qBittorrent's public address is the VPN exit, not the home address. Kill switch tested by taking `tun0` down inside gluetun: qBittorrent could not reach the internet by name or by address until gluetun restored the tunnel (about 30 s).
  - **qBittorrent:** save path `/data/torrents`, bound to `tun0`, categories `movies` and `tv`, web UI on 8090. Requests from the Docker bridge (`172.30.0.0/24`, i.e. the server itself) skip the login so Radarr and Sonarr can connect; LAN clients still need the password. In qBittorrent 5.3 these settings live in the `[WebUI]` section of `qBittorrent.conf`, not under `[Preferences]`. Added as the download client in Radarr and Sonarr.
  - **Still TODO:** indexers in Prowlarr; a login on each new app; Bazarr languages and providers.
- **NAS:** fixed the `homelab-backup` NFS rule (`192.168.4.46` to `192.168.68.81`), closing the leftover noted on 2026-11-27.
- **Port plan:** 5055 (Seerr), 6767 (Bazarr), 7878 (Radarr), 8090 (qBittorrent), 8989 (Sonarr) and 9696 (Prowlarr) are now in use.

## 2026-11-27

- **Router migration: eero → TP-Link Deco.** Subnet `192.168.4.0/22` → `192.168.68.0/22`, router `192.168.68.1`.
  - **Server:** `192.168.4.46` over USB Wi-Fi (`wlx90de8000ec5a`) → `192.168.68.81` over wired Ethernet (`eno1`, MAC `34:17:eb:b9:2e:09`), with a DHCP reservation in the Deco. (`docs/01`, `docs/02`)
  - **Synology:** `192.168.4.10` → `192.168.68.2`, with a DHCP reservation in the Deco. (`docs/01`, `docs/04`)
  - **Router DNS:** the Deco's DHCP Server Primary DNS is `192.168.68.81` (AdGuard), and IPv6 is off so devices can't bypass AdGuard over IPv6. Replaces the eero Custom DNS setup, which is kept in the docs as history. (`docs/05`, `docs/troubleshooting.md`)
  - **Fallback DNS steps** now use the Deco app. (`docs/03`, `docs/05`, `docs/troubleshooting.md`)
  - **Server fixes after the swap:** the server had no IP because `eno1` wasn't in netplan. Added `/etc/netplan/60-ethernet.yaml` (`dhcp4: true`), set the Wi-Fi to `optional: true` in `00-installer-config.yaml`, changed the Synology NFS rule on `media` to `192.168.68.81`, and changed the NAS IP in `/etc/fstab` to `192.168.68.2` (backup `/etc/fstab.bak-2026-11-27`), then remounted. (`docs/01`, `docs/04`, `docs/troubleshooting.md`)
  - **`health-check.sh`:** `DNS_SERVER` default changed to `192.168.68.81`. (`docs/03`)
  - **Network diagram:** updated the draw.io source with the new router, IPs and wired link.
  - Updated all IPs in the README and `docs/01`–`06`. Screenshots taken before the move still show the old IPs and are labelled as such.
- **Known leftover:** the NAS's `/volume1/homelab-backup` NFS export still lists the old server IP `192.168.4.46`. It isn't mounted yet. (`docs/04`)

## 2026-11-23

- **README:** moved the Skills demonstrated line above the Tools line.
- **Network diagram:** replaced the ASCII diagram in the README with a draw.io diagram (`docs/screenshots/network-diagram.png`), also embedded under Network in `docs/01`. The editable source is `docs/screenshots/network-diagram.drawio`, extracted from the PNG export, which moved from `docs/` to `docs/screenshots/`.
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
