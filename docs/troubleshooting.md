# Troubleshooting

An index of every problem I've hit. Each fix is written up once, in its doc's **Problems and fixes** section.

Before you change anything, run `./health-check.sh` ([03](03-docker.md#health-check)). The failing check usually points to the right row below.

| Symptom | Area | Fix |
|---|---|---|
| UEFI option greyed out after BIOS Load Defaults | BIOS | [02](02-ubuntu-install.md#uefi-greyed-out-after-load-defaults) |
| Rufus doesn't list the USB drive | Install media | [02](02-ubuntu-install.md#rufus-doesnt-show-the-usb-drive) |
| Corrupted filenames on a big, cheap USB stick | Install media | [02](02-ubuntu-install.md#usb-stick-with-likely-fake-capacity) |
| First SSH session closes after accepting the host key | SSH | [02](02-ubuntu-install.md#first-ssh-connection-closed-after-accepting-the-host-key) |
| SSH private key exposed | SSH | [02](02-ubuntu-install.md#private-ssh-key-exposed) |
| Password login still works over SSH | SSH | [02](02-ubuntu-install.md#ssh-key-only-login-planned) |
| High ping (~220 ms) on the server (old USB Wi-Fi setup) | Network | [01](01-hardware-and-planning.md#high-latency-over-usb-wi-fi) |
| Server has no IP after the router swap / `eno1` not in netplan | Network | [01](01-hardware-and-planning.md#no-ip-after-the-router-swap-eno1-not-in-netplan) |
| `/mnt/media` won't mount or NFS access denied after the IP change | NAS | [01](01-hardware-and-planning.md#no-ip-after-the-router-swap-eno1-not-in-netplan) |
| AdGuard needs port 53, but `systemd-resolved` holds it (stub listener disabled before first start) | DNS | [05](05-adguard-home.md#port-53-held-by-systemd-resolved) |
| AdGuard: forgot admin password / HTTP 429 login lockout | DNS | [05](05-adguard-home.md#forgot-the-admin-password-login-rate-limited) |
| eero Custom DNS greyed out (old router, before 2026-11-27) | Router | [05](05-adguard-home.md#eero-custom-dns-greyed-out) |
| Synology: can't create a shared folder; old pool data on the drives | NAS | [04](04-synology-nas-and-nfs.md#no-storage-pool-old-pool-data-on-the-drives) |
| `/mnt/media` is `rw` though the docs say `ro` / health check 2b fails | NAS | [04](04-synology-nas-and-nfs.md#docs-said-read-only-but-the-host-mount-was-read-write) |
| Health check passed but missed a problem | Docker | [03](03-docker.md#health-check-didnt-catch-a-read-write-nas-mount) |
| HEVC playback fails or maxes out the CPU | Jellyfin | [06](06-jellyfin.md#igpu-cant-transcode-hevc) |
| Jellyfin errors saving artwork, NFO or subtitles | Jellyfin | [06](06-jellyfin.md#jellyfin-features-that-write-to-a-read-only-share) |
| `git pull`: untracked `.gitignore` would be overwritten | Git | [07](07-version-control-and-tools.md#git-pull-fails-untracked-working-tree-files-would-be-overwritten-gitignore) |

## If DNS is down for the whole house

1. Check the container: `docker inspect -f '{{.State.Status}}' adguard`.
2. If you need DNS back right now, change the Deco's DHCP Server Primary DNS from `192.168.68.81` to a public resolver in the Deco app ([05](05-adguard-home.md#if-the-server-is-down)).
3. Only then investigate or restart AdGuard. AdGuard is the house DNS, so warn the household before restarting it. See [05](05-adguard-home.md).
