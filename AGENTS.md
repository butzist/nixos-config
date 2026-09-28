# AGENTS.md

Personal NixOS / nix-darwin / home-manager flake. Nix modules only, no
imperative configuration outside this repo.

## Navigation: use `index.txt`

Every folder in this repo contains an `index.txt` listing each file and a
one-line description. **Read the `index.txt` of a folder before reading the
files in it**, and follow the `index.txt` chain to decide where to look.
Do not `ls`/glob your way around, and do not read whole directories of files
speculatively.

**Keep `index.txt` files up to date.** Any time you add, delete, rename or
repurpose a file, update the `index.txt` of that folder (and of the parent
folder if the entry there is affected) in the same change. An `index.txt` that
lies is worse than none.

## `secrets/` is off limits — never read it

`secrets/` is a git submodule holding age-encrypted material and per-user
secrets. **Never open, read, grep, cat, or search any file inside `secrets/`,
including its `index.txt`.** Its layout is already documented by filename in
the consuming modules, so there is never a reason to read it.

If a task requires a change under `secrets/` (rotating a key, adding an
encrypted file, fixing a secret reference), **stop and tell the user what must
change and why.** Do not attempt the edit, do not guess at ciphertext, and do
not read the surrounding files to "check". Example of what to report:

> This needs a secret change: `secrets/users/<user>/` is missing the
> `id_ed25519.age` that `shared-modules/ssh-keys.nix` looks for, so that user
> gets no SSH key. Please add the file (or run your agenix re-encrypt flow) and
> tell me when it's in place.

## Structure

`flake.nix` is the single entry point. It declares flake inputs (nixpkgs
unstable + bleeding/security/stable aliases, nix-darwin, home-manager, stylix,
agenix, nvf, determinate, the local `freetoken` flake, and **ez-configs**) and
hands off to the `ez-configs` flake module. `ez-configs` is what makes module
directories work: any `.nix` in `nixos-modules/`, `darwin-modules/` and
`home-modules/` is a module whose basename is the name you can use in an
`imports` list via `with ezModules; [...]`. The host → user → home-module
wiring lives in `flake.nix` under `ezConfigs.nixos.hosts`.

| Folder | Purpose |
| --- | --- |
| `nixos-configurations/` | One directory per NixOS host. `default.nix` = hardware, bootloader, GPU, users, `ezModules` imports. `home.nix` = per-host `home-manager.sharedModules` (monitors, machine-local app config). `hardware-configuration.nix` is generated, do not hand-edit. |
| `nixos-modules/` | System-wide NixOS modules: `base`, `gnome`, `gaming`, `laptop`, `containers` (+ `containers-linux`/`containers-darwin` split by `mkIf` on the platform). |
| `darwin-modules/` | nix-darwin modules (`base`, `aerospace`). macOS, Hyprland-free. |
| `home-configurations/` | One file per home-manager user (`adam`, `mirj`, `games`, `work`). Selects which `ezModules` that user gets, adds user-specific packages, git identity (from `config.sensitive`), `home.stateVersion`. |
| `home-modules/` | Shared home-manager modules: `base`, terminal/shell, desktop, editors, dev tooling, and the `neovim/`, `waybar/`, `work/` subdirectories. |
| `shared-modules/` | Imported by both NixOS and darwin (`ssh-keys.nix`, `tailscale.nix`). Secret-consuming; see `secrets/`. |
| `overlays/` | `nixpkgs.overlays` shared by NixOS + home-manager. `default.nix` adds the `_bleeding`/`_security`/`_stable` package-set aliases; `build-fixes.nix` pins/patches packages. |
| `themes/` | stylix home-manager themes (`everforest-kingdoms`, `ubuntu-catppuccin`): colours, fonts, cursor, wallpaper, GTK. Imported directly by each `home-configurations/*.nix`. |
| `wallpapers/` | PNGs referenced by `stylix.image` in `themes/`. |
| `secrets/` | Git submodule. **Never read** — see above. |

## Conventions

- Keep `home.stateVersion` / `system.stateVersion` pinned per host; do not bump
  them as part of unrelated work.
- Comments in this repo explain *why* (e.g. the pipewire A2DP note in
  `nixos-modules/base.nix`). Keep that style when editing.
- Validate with `nix flake check` or a `nixos-rebuild --flake .?submodules=1`
  dry run when the toolchain is available; the repo has no test suite.
- Helper scripts in the root (`rebuild-system.sh`, `rebuild-darwin.sh`,
  `rebuild-user.sh`, `collect-garbage.sh`) all pass `?submodules=1`, so the
  `secrets/` submodule is expected to be populated locally.
