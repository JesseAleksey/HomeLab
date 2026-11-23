# 02 · Ubuntu Server install

## Goal

Get a clean, headless Ubuntu Server on the OptiPlex 7010 that I can manage over SSH.

## What I built

- Ubuntu Server 26.04.1 LTS (standard, not minimized), Legacy BIOS boot.
- Whole SanDisk SSD (111.8 GiB) as one ext4 root partition, without LVM.
- Hostname `jaramilloserver`, user `jesse_j`, OpenSSH server.
- Wi-Fi configured in the installer through the USB adapter (`wlx90de8000ec5a`).

## Steps

### 1. BIOS (F2 at power-on)

1. **Load Defaults.**
2. Enable **Virtualization (VT)**.
3. Set **SATA Operation** to **AHCI**.
4. Set **AC Recovery** to **Power On**, so the server boots by itself after a power cut.
5. Boot mode: **Legacy**. UEFI was greyed out ([below](#uefi-greyed-out-after-load-defaults)).

### 2. Installer USB (Rufus 4.16, on Windows)

| Setting | Value |
|---|---|
| Show advanced drive properties | **List USB Hard Drives** ticked |
| Partition scheme | **MBR** |
| Target system | **BIOS (or UEFI-CSM)** |
| GRUB prompt | **Yes**, to download GRUB 2.14 |

### 3. Install

Boot from the USB with **F12** (one-time boot menu), then:

- **Ubuntu Server**, not minimized.
- **Network:** set up Wi-Fi on the USB adapter.
- **Storage:** use the entire disk (SanDisk, 112 GB), with **Set up this disk as an LVM group** unticked.
- **Profile:** hostname `jaramilloserver`, user `jesse_j`.
- **SSH:** install OpenSSH server.
- **Featured snaps:** none selected.

### 4. First SSH login

From another machine: `ssh jesse_j@192.168.4.46`. Before you accept the host key, compare its fingerprint with the server console ([below](#first-ssh-connection-closed-after-accepting-the-host-key)).

## Verification

```bash
. /etc/os-release; echo "$PRETTY_NAME"      # Ubuntu 26.04.1 LTS
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT   # sda2 ext4 on /, no LVM
snap list                                   # see note below
```

Checked 2026-11-23: matches the above. No featured snaps were chosen, but `snap list` still shows `core24`, `snapd` and `hwctl`, which came with the base install.

## Problems and fixes

### UEFI greyed out after Load Defaults

After **Load Defaults**, the **UEFI** boot mode option was greyed out and couldn't be selected.

Fix: stay on **Legacy** and write the installer USB as **MBR / BIOS (or UEFI-CSM)**. A GPT/UEFI-only stick won't boot in Legacy mode.

### Rufus doesn't show the USB drive

Rufus hides drives it treats as "fixed" disks (common with USB SSDs, enclosures and some large or cheap flash drives).

- Expand **Show advanced drive properties** and tick **List USB Hard Drives** (or press **Alt+F**).
- Close anything holding the drive open (Explorer windows, other imaging tools), then refresh.

### USB stick with likely fake capacity

The installer USB was a generic "1 TB" drive. A corrupted filename suggests it's a fake-capacity drive: it reports more space than it has, and data written past the real size gets corrupted.

- TODO: what did you do about it (re-write, different stick)? Did the install media check pass?
- Before using a stick like this again, test it with H2testw (Windows) or `f3write`/`f3read` (Linux).

### First SSH connection closed after accepting the host key

The first `ssh` session closed straight after I accepted the host key.

Fix: compared the fingerprint with the one on the server console, confirmed they matched, and reconnected. That worked. To see the fingerprint on the console:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

TODO: cause unknown.

## What I learned

- On old Dell BIOSes, Load Defaults can lock you into Legacy boot. Match the USB's partition scheme to the boot mode rather than fighting it.
- AC Recovery = Power On matters for a machine that's the house DNS.
- Cheap high-capacity USB sticks can lie about their size.
- TODO: add your own notes.

## Next steps

- [ ] Test or throw away the suspect "1 TB" USB stick.
- [ ] TODO: SSH hardening (key-only login), if you want it.
- [ ] Reinstall on the HP ProDesk 600 G6 when it's ready ([01](01-hardware-and-planning.md#next-steps)).
