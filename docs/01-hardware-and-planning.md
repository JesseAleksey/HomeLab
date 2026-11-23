# 01 · Hardware and planning

## Goal

Run house-wide DNS ad-blocking and a media server on hardware I already owned, with the media itself on a NAS.

## What I built

I repurposed the Dell OptiPlex 7010 because I already had it. It's a stopgap: an HP ProDesk 600 G6 is planned as the future host (see [Next steps](#next-steps)).

| Role | Device | Details |
|---|---|---|
| Docker host (`jaramilloserver`) | Dell OptiPlex 7010 | Intel Core i5-3570 (4C/4T, 3.4 GHz, HD Graphics 2500), 8 GB RAM, SanDisk SSD Plus 120 GB (`SDSSDA120G`, 111.8 GiB usable), Legacy BIOS boot |
| Host OS | Ubuntu Server 26.04.1 LTS | Docker + Docker Compose ([03](03-docker.md)) |
| Network | USB Wi-Fi adapter | Interface `wlx90de8000ec5a` |
| NAS | Synology DS214se | 2 × 3 TB, SHR (1-drive fault tolerance), `/volume1/media` over NFS ([04](04-synology-nas-and-nfs.md)) |
| Router | eero | DHCP for the LAN; custom DNS points at the Docker host |

### Network

Subnet: `192.168.4.0/22`

| Device | IP | MAC | Notes |
|---|---|---|---|
| eero router | `192.168.4.1` | — | Custom DNS set to `192.168.4.46` |
| Synology DS214se | `192.168.4.10` | `00:11:32:44:23:E4` | DHCP reservation, and the same IP set as static on the Synology itself; NFS server |
| OptiPlex 7010 (`jaramilloserver`) | `192.168.4.46` | `90:de:80:00:ec:5a` (Wi-Fi) | DHCP reservation; AdGuard Home + Jellyfin |

### Port plan

Both containers use `network_mode: host`, so they bind straight to the host's ports. That keeps DNS and Jellyfin's LAN discovery simple, but two services on the same port means one fails at start. Check this table before adding a service, and update it when ports change.

| Port | Assigned to | Status |
|---|---|---|
| 53 | AdGuard Home DNS | In use |
| 80, 443 | Nginx Proxy Manager | Reserved |
| 3000 | AdGuard Home first-run wizard | Setup only |
| 3001 | Uptime Kuma | Reserved |
| 3002 | Grafana | Reserved |
| 7359/udp | Jellyfin client discovery | In use |
| 8080 | AdGuard Home admin | In use |
| 8096 | Jellyfin | In use |

## Steps

1. Pick a host and a static address plan (table above).
2. In the eero app, add DHCP reservations: `jaramilloserver` → `192.168.4.46` (MAC `90:de:80:00:ec:5a`), Synology → `192.168.4.10` (MAC `00:11:32:44:23:E4`). The Synology also has `192.168.4.10` set manually as a static IP in DSM, matching the reservation ([04](04-synology-nas-and-nfs.md#what-i-built)). The server is the house DNS, so its address must never change.
3. Reserve ports for planned services before installing anything ([port plan](#port-plan)).

## Verification

On the server, the Wi-Fi adapter's MAC and address should match the reservation:

```bash
ip -br link show wlx90de8000ec5a    # 90:de:80:00:ec:5a
ip -br -4 addr show wlx90de8000ec5a # 192.168.4.46/22
```

Checked 2026-11-23: both match. Both reservations (`.46` and `.10`) are set in the eero app.

## Problems and fixes

### High latency over USB Wi-Fi

Pings of around 220 ms over the USB Wi-Fi adapter.

- The ~220 ms was `ping google.com` run from the server on 2026-11-22, right after freeing port 53 for AdGuard.
- Retest from the server on 2026-11-23 was normal: router `192.168.4.1` avg 5 ms, NAS `192.168.4.10` avg 3 ms, `1.1.1.1` avg 54 ms (20–85 ms, high jitter). So the 220 ms was a one-time spike.

## What I learned

- Old hardware is good enough for a home server. An i5-3570 with 8 GB runs DNS and a media server easily; the limits show up in video transcoding, not everyday services.
- Planning IPs and ports up front saves trouble later. With host networking, two services can't share a port, so a port plan prevents conflicts before they happen.
- A DNS server needs a fixed address. If its IP changes, the whole house loses internet, so DHCP reservations aren't optional.

## Next steps

- [ ] Wired Ethernet for reliability. After the switch, update the MAC in the DHCP reservation and the interface name in this doc.
- [ ] Move to an HP ProDesk 600 G6 (i5-10500, 16 GB) once it has an NVMe SSD.
- [ ] Add the reserved services: Nginx Proxy Manager, Uptime Kuma, Grafana.
