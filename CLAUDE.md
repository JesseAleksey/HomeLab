# CLAUDE.md

Guidance for Claude Code when working in this homelab repo. Setup details and fixes live in `docs/` (index: `docs/troubleshooting.md`); log changes in `CHANGELOG.md`.

## Rules

1. **This server is the DNS for the whole house.** Never stop, restart, recreate, or update the `adguard` container (including `docker compose down`, `restart`, `up -d` that would recreate it, or `pull` + `up`) without asking first. If AdGuard goes down, every device on the network loses DNS.
2. **Explain what you're about to do before running commands.** Say what the command does and why, then run it.
3. **Never commit anything in `adguard/` or `jellyfin/`.** They hold runtime data, logs, and password hashes and are git-ignored. Don't read them into commits, READMEs, or docs, and don't `git add -f` them.

## Hardware

| Device | Details |
|---|---|
| Docker host (`jaramilloserver`) | Dell OptiPlex 7010, Intel Core i5-3570, 8 GB RAM, Ubuntu Server 26.04 |
| NAS | Synology DS214se, SHR mirror |
| Router | eero |

## Network

Subnet: `192.168.4.0/22`

| Device | IP | Notes |
|---|---|---|
| eero router | `192.168.4.1` | Custom DNS points at this server (`192.168.4.46`) |
| Synology DS214se | `192.168.4.10` | NFS export `/volume1/media` |
| OptiPlex 7010 | `192.168.4.46` | Connected over USB Wi-Fi (`wlx90de8000ec5a`) |

The NFS share `192.168.4.10:/volume1/media` is **read-only at both levels**:
- **Host:** mounted at `/mnt/media` with `ro,_netdev` in `/etc/fstab` (backup of the previous version: `/etc/fstab.bak-2026-11-23`).
- **Container:** bind-mounted into Jellyfin as `/mnt/media:/media:ro` in `docker-compose.yml`.

## Services

Both containers run with `network_mode: host` (see `docker-compose.yml`).

| Service | Port(s) | Notes |
|---|---|---|
| AdGuard Home | 53 TCP/UDP (DNS), 8080 (admin UI) | House-wide DNS; see Rule 1 |
| Jellyfin | 8096 | `/dev/dri` passed through; VAAPI hardware transcoding **H.264 only** (the i5-3570's HD 2500 iGPU can't do HEVC) |

## Port plan

| Port | Assigned to | Status |
|---|---|---|
| 53 | AdGuard Home DNS | In use |
| 80, 443 | Nginx Proxy Manager | Reserved |
| 3001 | Uptime Kuma | Reserved |
| 3002 | Grafana | Reserved |
| 8080 | AdGuard Home admin | In use |
| 8096 | Jellyfin | In use |

Check this table before adding a service, and update it when ports change. Because services use host networking, a port clash fails at container start.
