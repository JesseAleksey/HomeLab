# HomeLab

Self-hosted DNS ad-blocking and media streaming on a repurposed Dell OptiPlex, with media stored on a Synology NAS.

| Service | Purpose |
|---|---|
| [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) | House-wide DNS server and ad/tracker blocker |
| [Jellyfin](https://jellyfin.org/) | Media server, with VAAPI hardware transcoding (H.264 only) |

---

## Hardware

| Role | Device | Details |
|---|---|---|
| Docker host (`jaramilloserver`) | Dell OptiPlex 7010 | Intel Core i5-3570 (4C/4T, 3.4 GHz, HD Graphics 2500), 8 GB RAM, 120 GB SanDisk SSD, Legacy BIOS boot |
| Host OS | Ubuntu Server 26.04 | Docker + Docker Compose |
| Network | USB Wi-Fi adapter | Host connects over Wi-Fi (`wlx90de8000ec5a`) |
| NAS | Synology DS214se | SHR mirror; shared folder `/volume1/media` exported over NFS |
| Router | eero | DHCP for the LAN; custom DNS points at the Docker host |

## Network layout

Subnet: `192.168.4.0/22`

| Device | IP | Notes |
|---|---|---|
| eero router | `192.168.4.1` | Custom DNS set to `192.168.4.46` |
| Synology DS214se | `192.168.4.10` | NFS export `192.168.4.10:/volume1/media` |
| OptiPlex 7010 | `192.168.4.46` | AdGuard Home + Jellyfin, both on host networking |

```
            Internet
               │
       ┌───────┴────────┐
       │ eero           │ 192.168.4.1
       │ DNS → .4.46    │
       └───────┬────────┘
               │  LAN 192.168.4.0/22
     ┌─────────┴───────────────────┐
     │                             │
┌────┴──────────────────┐   ┌──────┴─────────────┐
│ jaramilloserver       │   │ Synology DS214se   │
│ 192.168.4.46 (Wi-Fi)  │   │ 192.168.4.10       │
│  ├─ AdGuard  :53/8080 │   │  /volume1/media    │
│  └─ Jellyfin :8096    │◄──┤  (NFS, SHR mirror) │
│ /mnt/media (NFS, ro)  │   └────────────────────┘
└───────────────────────┘
```

> The server gets its address from DHCP. Set a DHCP reservation for `192.168.4.46` on the eero so DNS doesn't break when the lease changes.

## Services and ports

Both containers use `network_mode: host`, so they bind directly to the host's ports. Images are pinned to a version tag plus digest in `docker-compose.yml`.

| Service | Port | Protocol | Use |
|---|---|---|---|
| AdGuard Home | 53 | TCP/UDP | DNS for the whole house |
| AdGuard Home | 8080 | TCP | Web admin UI: `http://192.168.4.46:8080` |
| AdGuard Home | 3000 | TCP | First-run setup wizard only |
| Jellyfin | 8096 | TCP | Web UI and clients: `http://192.168.4.46:8096` |
| Jellyfin | 7359 | UDP | Client auto-discovery on the LAN |

### Port plan

Because everything uses host networking, a port clash makes a container fail at start. Check this table before adding a service, and update it when ports change.

| Port | Assigned to | Status |
|---|---|---|
| 53 | AdGuard Home DNS | In use |
| 80, 443 | Nginx Proxy Manager | Reserved |
| 3001 | Uptime Kuma | Reserved |
| 3002 | Grafana | Reserved |
| 8080 | AdGuard Home admin | In use |
| 8096 | Jellyfin | In use |

### Volumes

| Container | Host path | Container path | Notes |
|---|---|---|---|
| adguard | `./adguard/work` | `/opt/adguardhome/work` | Query logs, stats (git-ignored) |
| adguard | `./adguard/conf` | `/opt/adguardhome/conf` | Config incl. credentials (git-ignored) |
| jellyfin | `./jellyfin/config` | `/config` | Library DB, users (git-ignored) |
| jellyfin | `./jellyfin/cache` | `/cache` | Transcode/image cache (git-ignored) |
| jellyfin | `/mnt/media` | `/media` | NAS media; read-only on the host (`ro` in fstab) and in the container (`:ro`) |
| jellyfin | `/dev/dri` | `/dev/dri` | iGPU passthrough for VAAPI transcoding |

## Setup

1. **Mount the NAS share read-only** (add to `/etc/fstab`):
   ```
   192.168.4.10:/volume1/media  /mnt/media  nfs  ro,_netdev  0  0
   ```
   ```bash
   sudo mkdir -p /mnt/media && sudo mount -a
   findmnt -no OPTIONS /mnt/media    # should start with "ro,"
   ```
   The media is read-only at both levels: the host mounts it `ro`, and Jellyfin gets it through the `/mnt/media:/media:ro` bind in `docker-compose.yml`. To switch an existing mount without unmounting: `sudo mount -o remount,ro /mnt/media`.
2. **Free port 53** (see [Port 53 conflict](#port-53-already-in-use-systemd-resolved)).
3. **Start the stack:**
   ```bash
   docker compose up -d
   ```
4. Open `http://192.168.4.46:3000` to run the AdGuard setup wizard (set the admin UI to port 8080), then `http://192.168.4.46:8096` for Jellyfin.
5. In Jellyfin, add `/media` as a library. Under *Dashboard → Playback → Transcoding*, choose **VAAPI** (device `/dev/dri/renderD128`) and enable hardware decoding for **H.264 only**. Leave HEVC unchecked: the i5-3570's HD Graphics 2500 can't do HEVC.
6. In the eero app, set custom DNS to `192.168.4.46`.

### Updating

> **AdGuard is the DNS for the whole house.** Recreating the `adguard` container takes DNS down for every device until it's back. Do it at a quiet time and have a fallback ready (e.g. temporarily switch the eero's DNS back to automatic).

Images are pinned by digest, so `docker compose pull` won't fetch anything new by itself. To update:

1. Change the tag and digest for the service in `docker-compose.yml`.
2. Update one service at a time, Jellyfin first:
   ```bash
   docker compose pull jellyfin && docker compose up -d jellyfin
   ```
3. Run `./health-check.sh`, then clean up with `docker image prune -f`.

### What's not in git

`adguard/` and `jellyfin/` hold runtime data, logs and password hashes, and are ignored along with `.env`, keys and certificates. Back these up separately; never commit them.

---

## Health check

`health-check.sh` is a **read-only** check of the whole stack. It never starts, stops or restarts anything.

```bash
./health-check.sh
```

| # | Check | Passes when |
|---|---|---|
| 1 | Containers | `adguard` and `jellyfin` are both `running` |
| 2 | NAS mount | `/mnt/media` is a mountpoint |
| 3 | Ad blocking | `doubleclick.net` is blocked (`0.0.0.0`, `NXDOMAIN`, `REFUSED`, or empty answer) |
| 4 | DNS resolution | `google.com` resolves to a real IP via AdGuard |
| 5 | Jellyfin | `GET /health` returns `Healthy` |
| 6 | Disk | Root filesystem usage is below 80% |

Each check prints `[PASS]` or `[FAIL]` (coloured when run in a terminal). The script exits `0` if everything passes and `1` if anything fails, so it works from cron or a monitoring tool.

Defaults can be overridden with environment variables:

| Variable | Default |
|---|---|
| `DNS_SERVER` | `192.168.4.46` |
| `MEDIA_MOUNT` | `/mnt/media` |
| `JELLYFIN_URL` | `http://localhost:8096` |
| `DISK_PATH` | `/` |
| `DISK_LIMIT` | `80` (percent) |

```bash
DISK_LIMIT=90 ./health-check.sh
```

Requires `docker`, `dig` (`dnsutils`), `curl` and `findmnt`.

---

## Troubleshooting

### UEFI greyed out after Load Defaults (OptiPlex 7010)

After running **Load Defaults** in the BIOS setup (**F2** at power-on), the **UEFI** boot mode option was greyed out and couldn't be selected.

Fix: don't fight it. Stay on **Legacy** boot and write the Ubuntu installer USB with an **MBR** partition scheme (see the Rufus settings below). A GPT/UEFI-only stick won't boot in Legacy mode. Use **F12** at power-on for the one-time boot menu to pick the USB stick.

### Rufus doesn't show the USB drive

Rufus hides drives it considers "fixed" disks (common with USB SSDs, enclosures and some large flash drives).

- Expand **Show advanced drive properties** and tick **List USB Hard Drives** (or press **Alt+F**).
- Close anything holding the drive open (Explorer windows, other imaging tools) and click refresh.
- Still missing? Run `diskpart` → `list disk` to confirm Windows sees it; if so, `clean` it and retry.
- For this machine, use **Partition scheme: MBR** and **Target system: BIOS (or UEFI-CSM)**.

### Port 53 already in use (systemd-resolved)

AdGuard fails to start with `bind: address already in use` because Ubuntu's `systemd-resolved` runs a stub DNS listener on `127.0.0.53:53`.

Turn off the stub listener and point the host's own resolver at `1.1.1.1`, so the server can still resolve names (e.g. to pull images) even when the AdGuard container is down:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/adguard.conf >/dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1
DNSStubListener=no
EOF
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved
docker compose up -d adguard
```

Check with `sudo ss -tulpn | grep ':53 '`; only AdGuard should be listening.

### Synology: can't create a shared folder ("storage pool required")

A fresh Synology with blank drives has no volume, so Shared Folder / NFS options are unavailable.

1. *Storage Manager → Storage → Create → Create Storage Pool*, choose **SHR** (with the DS214se's two drives this is a mirror), and select the drives.
2. Create a **Volume** on that pool (this gives you `/volume1`).
3. *Control Panel → File Services → NFS*: enable NFS.
4. *Control Panel → Shared Folder*: create `media`, then *Edit → NFS Permissions → Create*, hostname `192.168.4.46`, privilege Read-only, squash *Map all users to admin* if you hit permission errors.

### `git pull` fails: "untracked working tree files would be overwritten" (`.gitignore`)

Happens when `.gitignore` was created on GitHub (e.g. via the web UI) and also created locally but never committed. `git pull` refuses:

```
error: The following untracked working tree files would be overwritten by merge:
	.gitignore
Please move or remove them before you merge.
```

Fix: move the local file aside, pull, then append its rules to the pulled version:

```bash
mv .gitignore .gitignore.local
git pull
cat .gitignore.local >> .gitignore    # then remove any duplicate lines
rm .gitignore.local
git add .gitignore
git commit -m "Merge local .gitignore rules"
git push
```

Before pushing, confirm no private data slipped in:

```bash
git status --ignored          # adguard/ and jellyfin/ should be listed as ignored
git ls-files                  # should only show .gitignore, CLAUDE.md, README.md, docker-compose.yml, health-check.sh
```

If a data folder was already committed, untrack it without deleting it: `git rm -r --cached adguard jellyfin`.
