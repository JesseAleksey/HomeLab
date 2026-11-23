# Troubleshooting

An index of every problem I've hit. Each fix is written up once, in its doc's **Problems and fixes** section.

Before you change anything, run `./health-check.sh` ([03](03-docker.md#health-check)). The failing check usually points to the right row below.

| Symptom | Area | Fix |
|---|---|---|
| UEFI option greyed out after BIOS Load Defaults | BIOS | [02](02-ubuntu-install.md#uefi-greyed-out-after-load-defaults) |
| Rufus doesn't list the USB drive | Install media | [02](02-ubuntu-install.md#rufus-doesnt-show-the-usb-drive) |
| Corrupted filenames on a big, cheap USB stick | Install media | [02](02-ubuntu-install.md#usb-stick-with-likely-fake-capacity) |
| First SSH session closes after accepting the host key | SSH | [02](02-ubuntu-install.md#first-ssh-connection-closed-after-accepting-the-host-key) |
| High ping (~220 ms) on the server | Network | [01](01-hardware-and-planning.md#high-latency-over-usb-wi-fi) |
| AdGuard: `bind: address already in use` on port 53 | DNS | [05](05-adguard-home.md#port-53-already-in-use-systemd-resolved) |
| eero Custom DNS greyed out | Router | [05](05-adguard-home.md#eero-custom-dns-greyed-out) |
| Synology: can't create a shared folder; old pool data on the drives | NAS | [04](04-synology-nas-and-nfs.md#no-storage-pool-old-pool-data-on-the-drives) |
| `/mnt/media` is `rw` though the docs say `ro` / health check 2b fails | NAS | [04](04-synology-nas-and-nfs.md#docs-said-read-only-but-the-host-mount-was-read-write) |
| Health check passed but missed a problem | Docker | [03](03-docker.md#health-check-didnt-catch-a-read-write-nas-mount) |
| HEVC playback fails or maxes out the CPU | Jellyfin | [06](06-jellyfin.md#igpu-cant-transcode-hevc) |
| Jellyfin errors saving artwork, NFO or subtitles | Jellyfin | [06](06-jellyfin.md#jellyfin-features-that-write-to-a-read-only-share) |
| `git pull`: untracked `.gitignore` would be overwritten | Git | [07](07-github-and-claude-code.md#git-pull-fails-untracked-working-tree-files-would-be-overwritten-gitignore) |
| Claude Code login: "Pro is required" | Claude Code | [07](07-github-and-claude-code.md#claude-code-login-pro-is-required) |

## If DNS is down for the whole house

1. Check the container: `docker inspect -f '{{.State.Status}}' adguard`.
2. If you need DNS back right now, switch the eero's DNS to automatic in the eero app.
3. Only then investigate or restart AdGuard. See CLAUDE.md Rule 1 and [05](05-adguard-home.md).
