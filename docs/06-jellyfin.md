# 06 · Jellyfin

## Goal

Stream the NAS media library to devices in the house, with hardware transcoding where the old iGPU can do it, and never write to the media share.

## What I built

- Jellyfin `12.4` in Docker, host networking, web UI and clients on **8096**, LAN discovery on **7359/udp**.
- Media from the NAS at `/media`, read-only ([04](04-synology-nas-and-nfs.md)).
- `/dev/dri` passed through for **VAAPI** on the i5-3570's HD Graphics 2500, with **H.264 only** (this iGPU can't do HEVC).

| Library | Folder |
|---|---|
| Movies | `/media/Movies` |
| Shows | `/media/TV Shows` |

## Steps

1. `docker compose up -d jellyfin`, then open `http://192.168.4.46:8096` and complete the setup wizard.
2. Add the libraries above.
3. In each library's settings, turn off everything that writes to the media folders or overloads this CPU:

   | Setting | Set to | Why |
   |---|---|---|
   | NFO metadata saver | Off | The share is read-only |
   | Save artwork into media folders | Off | The share is read-only |
   | Save subtitles into media folders | Off | The share is read-only |
   | Save trickplay images next to media | Off | The share is read-only |
   | Real-time monitoring | Off | Doesn't work reliably on NFS (changes made on the NAS don't trigger events) |
   | Trickplay image extraction | Off | Too heavy for the i5-3570 |
   | Chapter image extraction | Off | Too heavy for the i5-3570 |

4. *Dashboard → Playback → Transcoding*: hardware acceleration **VAAPI**, device `/dev/dri/renderD128`. Enable hardware decoding for **H.264** only and leave **HEVC** unticked.

## Verification

```bash
curl -fsS http://localhost:8096/health     # Healthy
ls -l /dev/dri                              # renderD128 present
```

Checked 2026-11-23: health check 5 passes.

- TODO: confirm hardware transcoding during playback (*Dashboard → Activity*, or the playback info overlay shows "Transcoding" with VAAPI, and CPU stays low).
- TODO: which client apps you use (TV, phone, web).

## Problems and fixes

### iGPU can't transcode HEVC

The HD Graphics 2500 (Ivy Bridge) supports VAAPI for H.264 but not HEVC. Enabling HEVC hardware decoding would make those transcodes fail.

Fix: H.264 only for hardware decoding. HEVC falls back to the CPU, which will be slow. The future host's i5-10500 can handle HEVC ([01](01-hardware-and-planning.md#next-steps)).

### Jellyfin features that write to a read-only share

Jellyfin can save NFO files, artwork, subtitles and trickplay images next to the media by default, but the share is mounted `ro` at both the host and container level.

Fix: turned those savers off (table above), so metadata stays in `./jellyfin/config`.

## What I learned

- An old iGPU still helps, but check exactly which codecs it supports.
- With a read-only media share, Jellyfin has to keep all its metadata in its own config folder.
- NFS and real-time file monitoring don't mix.
- TODO: add your own notes.

## Next steps

- [ ] Confirm hardware transcoding and list client apps (TODOs above).
- [ ] TODO: set a scheduled library scan, since real-time monitoring is off.
- [ ] Revisit HEVC and trickplay on the HP ProDesk 600 G6.
