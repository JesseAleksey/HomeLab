# 05 · AdGuard Home

## Goal

Block ads and trackers for every device in the house at the DNS level, by making the server the eero's DNS.

> **AdGuard is the DNS for the whole house.** If the `adguard` container stops or gets recreated, every device loses DNS. See CLAUDE.md Rule 1 and the update procedure in [03](03-docker.md#updating).

## What I built

- AdGuard Home `v1.0.0` in Docker, host networking ([`docker-compose.yml`](../docker-compose.yml)).
- DNS on port **53** (TCP/UDP). The admin UI is on **8080**, which keeps 80 free for Nginx Proxy Manager.
- The host's own resolver bypasses AdGuard and uses `1.1.1.1`, so the server can still resolve names (e.g. to pull images) when AdGuard is down.

| Setting | Value |
|---|---|
| Blocklists (enabled) | AdGuard DNS filter, OISD Big (`https://big.oisd.nl`) |
| Blocklists (disabled) | AdAway |
| Upstream DNS | Cloudflare DoH, Quad9 DoH |
| Upstream mode | TODO: check *Settings → DNS settings → Upstream DNS servers* (load-balancing, parallel, or fastest IP) |
| Bootstrap DNS | `1.0.0.1`, `1.1.1.1` |

The settings above were not read from `adguard/conf`, which holds credentials and is never put into docs (CLAUDE.md Rule 3).

## Steps

1. Free port 53 on the host ([below](#port-53-already-in-use-systemd-resolved)).
2. `docker compose up -d adguard`.
3. Open `http://192.168.4.46:3000` for the first-run wizard. Set the admin UI to port **8080** and DNS to port **53**.
4. In the admin UI (`http://192.168.4.46:8080`):
   - *Filters → DNS blocklists*: enable AdGuard DNS filter, add OISD Big, disable AdAway.
   - *Settings → DNS settings*: set the upstreams and bootstrap DNS from the table above.
5. In the eero app, turn off **all eero Secure features** ([below](#eero-custom-dns-greyed-out)), then set **Custom DNS** to `192.168.4.46`.

## Verification

From a laptop on the LAN:

```
nslookup doubleclick.net
Server:  192.168.4.46
...
Address: 0.0.0.0
```

The answer should come from `192.168.4.46` and resolve to `0.0.0.0`, which means it's blocked.

From the server (also checked by health checks 3 and 4):

```bash
dig @192.168.4.46 doubleclick.net +short   # 0.0.0.0
dig @192.168.4.46 google.com +short        # a real IP
sudo ss -tulpn | grep ':53 '               # only AdGuard listening
```

Checked 2026-11-23: health checks 3 and 4 pass, and port 53 is held on `*:53` (TCP and UDP).

## Problems and fixes

### Port 53 already in use (systemd-resolved)

AdGuard failed to start with `bind: address already in use`, because Ubuntu's `systemd-resolved` runs a stub DNS listener on `127.0.0.53:53`.

Fix: turn off the stub listener and point the host's resolver at `1.1.1.1`:

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

Checked 2026-11-23: the override file is in place and `/etc/resolv.conf` → `/run/systemd/resolve/resolv.conf`.

### eero Custom DNS greyed out

The Custom DNS option in the eero app couldn't be changed.

Fix: turn off **all eero Secure features** (eero Plus ad blocking and filtering use their own DNS). After that, Custom DNS can be set.

## If the server is down

Every device loses DNS while AdGuard is down. To get the house back online:

1. In the eero app, go to **Settings → Network settings → DNS** and choose **ISP DNS (Default)**.
2. After the server is fixed, switch back to **Custom** DNS `192.168.4.46`.

## What I learned

- Ubuntu's own DNS stub will clash with any DNS server on port 53.
- Keep the host's resolver independent of the container it runs, or a broken AdGuard can stop you pulling the image that fixes it.
- Router "security" features can quietly lock DNS settings.
- TODO: add your own notes.

## Next steps

- [ ] Fill in the upstream mode.
- [x] A fallback DNS plan for when the server is down: switch the eero back to ISP DNS ([steps](#if-the-server-is-down)).
- [ ] Put the admin UI behind Nginx Proxy Manager (80/443) once it's set up.
