# 02 · Ubuntu Server install

## Goal

Get a clean, headless Ubuntu Server on the OptiPlex 7010 that I can manage over SSH.

## What I built

- Ubuntu Server 26.04.1 LTS (standard, not minimized), Legacy BIOS boot.
- Whole SanDisk SSD (111.8 GiB) as one ext4 root partition, without LVM.
- Hostname `jaramilloserver`, user `jesse_j`, OpenSSH server.
- Wi-Fi configured in the installer through the USB adapter (`wlx90de8000ec5a`). Since 2026-11-27 the server uses wired Ethernet (`eno1`) and the Wi-Fi is `optional: true` ([01](01-hardware-and-planning.md#no-ip-after-the-router-swap-eno1-not-in-netplan)).

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

From another machine: `ssh jesse_j@192.168.68.81`. Before you accept the host key, compare its fingerprint with the server console ([below](#first-ssh-connection-closed-after-accepting-the-host-key)).

### 5. Time zone

Set to `America/Chicago` on 2026-11-23, so logs and commits show local time:

```bash
sudo timedatectl set-timezone America/Chicago
timedatectl | grep 'Time zone'    # America/Chicago (CST, -0600)
```

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

- I used it anyway, because the installer only writes ~3 GB at the start of the drive. The install completed and the system boots fine. I didn't run the install media check.
- I won't use this stick for real data.
- Before using a stick like this again, test it with H2testw (Windows) or `f3write`/`f3read` (Linux).

### First SSH connection closed after accepting the host key

The first `ssh` session closed straight after I accepted the host key.

Fix: compared the fingerprint with the one on the server console, confirmed they matched, and reconnected. That worked. To see the fingerprint on the console:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Cause unknown. It happened once, on the first connection after install, and retrying worked.

### Private SSH key exposed

I accidentally exposed my SSH private key.

Fix (2026-11-23):

1. Deleted the exposed private key.
2. Generated a new ed25519 key (no passphrase): `ssh-keygen -t ed25519`.
3. Overwrote `~/.ssh/authorized_keys` on the server with only the new public key, so the old key no longer works.
4. Backed up the new key in Bitwarden.

Password login is still enabled, so key-only login is the next step ([below](#ssh-key-only-login-planned)).

## What I learned

- The install media has to match the boot mode. When UEFI was greyed out, I had to stay on Legacy and build the USB with MBR instead of GPT.
- Tools hide things for safety. Rufus hid my USB until I enabled "List USB Hard Drives," and checking drive size before writing kept me from wiping the wrong disk.
- Linux config can be overridden by files you don't expect. A cloud-init drop-in file controlled SSH password login, and sshd uses the first value it reads.
- A private key must never leave the machine. When I exposed mine, the right fix was to rotate it: generate a new key and remove the old one from `authorized_keys`.

## Next steps

- [ ] Test or throw away the suspect "1 TB" USB stick.
- [x] Replace the exposed SSH key ([above](#private-ssh-key-exposed)).
- [ ] SSH key-only login: set `PasswordAuthentication no` in `50-cloud-init.conf` ([below](#ssh-key-only-login-planned)).
- [x] Set the time zone to `America/Chicago` ([above](#5-time-zone)).
- [ ] Reinstall on the HP ProDesk 600 G6 when it's ready ([01](01-hardware-and-planning.md#next-steps)).

### SSH key-only login (planned)

Not done yet. `sudo sshd -T | grep -i passwordauthentication` shows `passwordauthentication yes`, which comes from `/etc/ssh/sshd_config.d/50-cloud-init.conf`.

That drop-in sets `PasswordAuthentication yes`. sshd uses the **first** value it reads for each setting, and it reads the `sshd_config.d/` drop-ins before the rest of the main `sshd_config`, so the cloud-init file wins. To turn password login off, change it in `50-cloud-init.conf` (after a backup), not just in `sshd_config`. Then validate with `sudo sshd -t`, reload ssh, and confirm that key login still works from a second session before closing the first.
