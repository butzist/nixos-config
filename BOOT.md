# Boot, Secure Boot and TPM2 auto-unlock on `legion`

Implementation lives in `nixos-modules/boot.nix` (imported by every NixOS host
via `nixos-modules/default.nix`). Host-specific settings are in
`nixos-configurations/legion/default.nix` under `security.secureBoot`.

The module owns **all** boot configuration:

- plymouth / quiet kernel params / `linuxPackages_latest`
- loader selection: plain **systemd-boot** when
  `security.secureBoot.enable = false`, **Lanzaboote** when it is `true`
- optional systemd-pcrlock TPM2 unlock for the LUKS devices listed in
  `security.secureBoot.luksDevices`

Exactly one loader is active; the option is the switch. Hosts must not set
`boot.loader.systemd-boot.enable` themselves, or the two definitions clash.

## Swap

Swap is **not** a persistent LUKS container. `hardware-configuration.nix` points
at the bare partition by PARTUUID with `randomEncryption.enable`, so each boot
gets `cryptsetup plainOpen -d /dev/urandom` plus a fresh `mkswap`. No header, no
keyslot, no passphrase, nothing to enroll, and old contents are gone after
power-off. If that unit fails you lose swap, not the boot.

## Threat model

Secure Boot (db = your key + Microsoft's) means the firmware only runs images
signed by a key in db — not necessarily by _your_ key. That is why PCR 4 is
still pinned: the TPM only releases the LUKS key to the exact signed UKIs you
built, so a Microsoft-signed loader that Secure Boot would accept cannot decrypt
the disk. PCR 4 + PCR 7 together are what bind the key to your chain.

## 1. Lanzaboote, Secure Boot still OFF

```bash
cd ~/nix
nix flake lock                                  # lanzaboote input
sudo sbctl create-keys                          # keys only, no firmware change
sudo nixos-rebuild boot --flake '.?submodules=1'
```

`boot` installs and signs UKIs and generates the first pcrlock policy without
restarting the running system. Verify before rebooting:

```bash
sudo sbctl status
sudo sbctl verify          # every /boot/EFI/**/*.efi must say signed
sudo bootctl list | head -40
```

Reboot (Secure Boot still off), then open the boot menu and boot the previous
generation once. That is the rollback drill.

After this boot the pcrlock policy describes the real chain:

```bash
sudo bootctl status | grep -E 'Current|System|Secure Boot'
sudo systemctl status systemd-pcrlock-make-policy.service
```

## 2. Enroll keys and enable Secure Boot

1. Firmware setup (F2): Secure Boot **Disabled** → **Reset to Setup Mode**.
2. Back in NixOS:

```bash
sudo sbctl status                        # Setup Mode: Enabled
sudo sbctl enroll-keys --microsoft
```

`--microsoft` keeps Microsoft's UEFI CA in `db` so option ROMs (dGPU, NIC) and
firmware capsules still validate. Add `--firmware-builtin` only if something
breaks. Never `--yes-this-might-brick-my-machine`.

3. Firmware setup: **enable Secure Boot**.
4. Verify, then reboot and boot an older generation from the menu:

```bash
sudo bootctl status | grep -E 'Secure Boot|Setup Mode'
sudo sbctl status
sudo sbctl verify
```

## 3. TPM2 auto-unlock

Only from a boot where Secure Boot is enabled and the pcrlock policy was
generated from that exact chain:

```bash
sudo secure-boot-enroll
```

The script is generated from `security.secureBoot.luksDevices`, so the device
list lives in one place. It runs
`systemd-cryptenroll --tpm2-device=auto
--tpm2-pcrlock=/var/lib/systemd/pcrlock.json`
for each listed volume, without `--wipe-slot` on the first run. Verify the
passphrase slot survived:

```bash
sudo cryptsetup luksDump /dev/disk/by-uuid/e0024875-92ff-44be-adf2-7e2906bf4d0b | grep -A4 -E '^Keyslots|^Tokens'
sudo cryptsetup open --test-passphrase /dev/disk/by-uuid/e0024875-92ff-44be-adf2-7e2906bf4d0b
```

Expect the existing passphrase keyslot plus one new tpm2 slot, and a
`systemd-tpm2` token. Reboot: no prompt.

## Switching to "boot, but never auto-unlock"

Keep Secure Boot on and drop the TPM policy — no firmware changes, no unsigned
loader:

```nix
security.secureBoot = {
  enable = true;
  luksDevices = [];   # measured boot and tpm2-device=auto both go away
};
```

Every boot stops at the LUKS passphrase prompt; Secure Boot still verifies the
signed UKIs. Put the device back in `luksDevices` to re-enable auto-unlock.

## Switching back to plain systemd-boot

Only do this **after** disabling Secure Boot in the firmware. `enable = false`
installs an unsigned systemd-boot, and Secure Boot is enforced by the firmware
before any Linux code runs: an unsigned loader is never executed, so there is no
"boots but withholds the key" fallback. Recovery without a working bootloader is
still possible — the signed UKIs remain in `/boot/EFI/Linux/` and most firmwares
can start one directly via "boot from file" — but disable Secure Boot first.

```nix
security.secureBoot.enable = false;
```

Then rebuild. The old `EFI/Linux` UKIs stay on the ESP and systemd-boot will
list them; remove them if the menu looks wrong:

```bash
sudo rm -rf /boot/EFI/Linux /boot/loader/entries
sudo nixos-rebuild boot --flake '.?submodules=1'
```

## When does what happen

| Event                                        | Auto-unlock | Action needed                                                                          |
| -------------------------------------------- | ----------- | -------------------------------------------------------------------------------------- |
| `nixos-rebuild` (kernel/initrd/cmdline/UKI)  | Yes         | none — `lzbt` + `systemd-pcrlock` update NV index 770                                  |
| Boot an older generation                     | Yes         | none — signed, with its own PCR 4 prediction                                           |
| Secure Boot disabled in firmware (PCR 7)     | No          | passphrase, or re-enable Secure Boot                                                   |
| Firmware update (PCR 0/7 not in the policy)  | Yes         | none                                                                                   |
| Firmware update that resets Secure Boot vars | No          | passphrase once, then re-enroll keys                                                   |
| TPM cleared / replaced                       | No          | passphrase, then `secure-boot-enroll --wipe-slot=tpm2`                                 |
| Unsigned loader installed while SB is on     | —           | firmware refuses to execute it; disable SB or boot a signed UKI from `/boot/EFI/Linux` |
| `/var/lib/sbctl` lost                        | —           | already-signed UKIs still boot; recreate keys and re-enroll (see Recovery)             |

## Recovery

- **Bad generation:** pick the previous one in the boot menu (4 are on the ESP).
- **Any TPM problem:** type the LUKS passphrase; nothing is lost.
- **Secure Boot misbehaves:** firmware setup → disable Secure Boot. The same
  signed UKIs still boot; the TPM refuses and you use the passphrase.
- **Lost `/var/lib/sbctl`:** the machine still boots the already-signed
  generations; only new signing fails. Recover with Secure Boot off:
  1. firmware setup → **Reset to Setup Mode**
  2. `sudo sbctl create-keys`
  3. `sudo nixos-rebuild boot --flake '.?submodules=1'` — re-signs every
     generation on the ESP with the new key
  4. `sudo sbctl enroll-keys --microsoft`
  5. enable Secure Boot in firmware The LUKS/TPM side needs nothing: the
     passphrase keyslot is untouched and `systemd-pcrlock` regenerates the
     policy (at most one passphrase boot, if PCR 7 changed). Only if the
     firmware reset also cleared the TPM do you need `secure-boot-enroll` again.
- **ESP damaged:** boot a NixOS USB, mount ESP at `/boot` and root at `/mnt`,
  `nixos-enter`, then `nixos-rebuild boot --flake /path?submodules=1`.
- **No POST past firmware:** firmware setup, disable Secure Boot (no firmware
  password is set, so this always works).
