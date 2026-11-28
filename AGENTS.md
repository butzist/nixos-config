# AGENTS.md

Personal NixOS / nix-darwin / home-manager flake. Nix modules only, no
imperative configuration outside this repo.

## Navigation: use `index.txt`

Every folder in this repo contains an `index.txt` listing each file and a
one-line description. **Read the `index.txt` of a folder before reading the
files in it**, and follow the `index.txt` chain to decide where to look. Do not
`ls`/glob your way around, and do not read whole directories of files
speculatively.

**Keep `index.txt` files up to date.** Any time you add, delete, rename or
repurpose a file, update the `index.txt` of that folder (and of the parent
folder if the entry there is affected) in the same change. An `index.txt` that
lies is worse than none.

**Keep `index.txt` entries short and category-level.** One line per file: say
what kind of configuration it holds, not everything it installs or sets. For
example,
`adam.nix — home-manager settings, theme and installed programs for
user adam`.
Do not enumerate packages, modules, keybindings or individual settings; name
categories instead. Keep only the notes needed to navigate (unused files,
generated files, `DO NOT READ`).

## `secrets/` is off limits — never read it

`secrets/` is a git submodule holding age-encrypted material and per-user
secrets. **Never open, read, grep, cat, or search any file inside `secrets/`,
including its `index.txt`.** Its layout is already documented by filename in the
consuming modules, so there is never a reason to read it.

If a task requires a change under `secrets/` (rotating a key, adding an
encrypted file, fixing a secret reference), **stop and tell the user what must
change and why.** Do not attempt the edit, do not guess at ciphertext, and do
not read the surrounding files to "check". Example of what to report:

> This needs a secret change: `secrets/users/<user>/` is missing the
> `id_ed25519.age` that `shared-modules/ssh-keys.nix` looks for, so that user
> gets no SSH key. Please add the file (or run your agenix re-encrypt flow) and
> tell me when it's in place.

The `opencode` agent jail does not see the real tree: the `.envrc` builds the
`fake-secrets` flake package and adds `--ro-bind`s for `secrets/` and a
`safe.directory` git config to the jail through agent-toolbox's
`JAIL_EXTRA_ARGS`. The stub has no usable keys, only what the modules need to
evaluate, so evaluating inside the jail gives a configuration with a fake git
identity and placeholder age files. Nix copies submodule content only for
`?submodules=1` and only when the path is a git repository, hence:

    nix flake check 'git+file:///home/work/nix?submodules=1'

(or `--flake .?submodules=1`). Untracked files are invisible to Nix as well, so
`git add` new files before checking. Do not stage or commit `secrets/` from
inside the jail: the stub is a different repository and its HEAD is not the
submodule commit the real tree points at.

## Structure

`flake.nix` is the single entry point, but it declares **no native flake
inputs**. `.tack/pins.toml` declares every source and `.tack/pins.lock.json`
pins its revision; `flake.lock` is deliberately a no-input stub. `flake.nix`
imports `.tack` once and hands the raw pins to `ez-configs` as `tack`.
`shared-modules/sources.nix` derives the `sources` module argument: `sources`
keeps the raw flake sources, adds underscored nixpkgs aliases
(`sources._security`, `sources._stable`, `sources._unstable`), exposes local
derivations as `sources.customPkgs`, and installs the same aliases into `pkgs`
so `with pkgs; [ _stable.foo ]` keeps working. Underscores avoid name collisions
with derivation arguments. `ez-configs` is what makes module directories work:
any `.nix` in `nixos-modules/`, `darwin-modules/` and `home-modules/` is a
module whose basename is the name you can use in an `imports` list via
`with ezModules; [...]`. The host → user → home-module wiring lives in
`flake.nix` under `ezConfigs.nixos.hosts`.

| Folder                  | Purpose                                                                                                                                                                                                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nixos-configurations/` | One directory per NixOS host. `default.nix` = hardware, bootloader, GPU, users, `ezModules` imports. `home.nix` = per-host `home-manager.sharedModules` (monitors, machine-local app config). `hardware-configuration.nix` is generated, do not hand-edit. |
| `nixos-modules/`        | System-wide NixOS modules: `base`, `gnome`, `gaming`, `laptop`, `containers` (+ `containers-linux`/`containers-darwin` split by `mkIf` on the platform).                                                                                                   |
| `darwin-modules/`       | nix-darwin modules (`base`, `aerospace`). macOS, Hyprland-free.                                                                                                                                                                                            |
| `home-configurations/`  | One file per home-manager user (`adam`, `mirj`, `games`, `work`). Selects which `ezModules` that user gets, adds user-specific packages, git identity (from `config.sensitive`), `home.stateVersion`.                                                      |
| `home-modules/`         | Shared home-manager modules: `base`, terminal/shell, desktop, editors, the `development/` tree (dev packages, jailed agents, Herdr, rust-mold), and the `neovim/`, `waybar/`, `work/` subdirectories.                                                      |
| `shared-modules/`       | Imported by NixOS, darwin and home-manager (`sources.nix`, `ssh-keys.nix`, `tailscale.nix`). Secret-consuming modules; see `secrets/`.                                                                                                                     |
| `.tack/`                | Tack pins, resolved lock and vendored patches (see index.txt).                                                                                                                                                                                             |
| `packages/`             | Local derivations exposed as `sources.customPkgs` (see index.txt).                                                                                                                                                                                         |
| `todos/`                | Pure Nix checks whose due messages become NixOS `config.warnings` during rebuild (see index.txt).                                                                                                                                                          |
| `themes/`               | stylix home-manager themes (`bosque-kingdoms`, `ubuntu-catppuccin`): colours, fonts, cursor, wallpaper, GTK. Imported directly by each `home-configurations/*.nix`.                                                                                        |
| `wallpapers/`           | PNGs referenced by `stylix.image` in `themes/`.                                                                                                                                                                                                            |
| `secrets/`              | Git submodule. **Never read** — see above.                                                                                                                                                                                                                 |

## Conventions

- Keep `home.stateVersion` / `system.stateVersion` pinned per host; do not bump
  them as part of unrelated work.
- Comments in this repo explain _why_ (e.g. the pipewire A2DP note in
  `nixos-modules/base.nix`). Keep that style when editing.
- Update sources with `just update` (`tack update`), not `nix flake update`.
  Commit `.tack/pins.lock.json` and any vendored `.tack/patches/` or
  `.tack/diffs/` changes; `flake.lock` must stay the no-input stub.
- Put local derivations in `packages/` as plain `.nix` files and expose them
  from `default.nix`; they appear as `sources.customPkgs`. Use
  `tack patch add <pin> <url>` only for changes to an upstream source tree.
- Binary caches are the literal `nixConfig` block in `flake.nix`; Nix reads
  flake config only from the top-level flake and requires literal values, so do
  not split them into another file. Keep deferred upgrades as pure Nix
  conditions in `todos/checks.nix` so rebuild warnings stay pure.
- TODO checks are temporary. When an upgrade lands, remove its entry and any
  now-unused condition from `todos/checks.nix` in the same change; do not leave
  resolved warnings behind. Use `just todos` / `just todo <name>` to confirm.
- Validate with `nix flake check 'git+file:...?submodules=1'` or a
  `nixos-rebuild --flake .?submodules=1` dry run when the toolchain is
  available; the repo has no test suite. Nix ignores untracked files, so
  `git add` new files (or `git add -N`) before checking.
- `nix develop` provides `nixd`, `alejandra`, `statix`, `deadnix`, `agenix`,
  `tack`, `nix-tree`, `nom`, `nix-diff`, `nix-update`, and `just`; `nix fmt`
  uses `alejandra`.
- Root `justfile`: `just switch` rebuilds and switches the current platform
  (NixOS on Linux, nix-darwin on macOS); bare `just` is the same. `just boot`
  installs/signs boot entries without switching; `just enroll keys` enrolls
  Secure Boot keys and `just enroll disk` enrolls TPM2 LUKS unlock;
  `just install nix|hm` bootstraps tools. `just build`, `just update`,
  `just patch-add <pin> <url>`, `just update-apply`, `just check`, `just todos`,
  `just todo <name>`, `just fmt` and `just gc` build or maintain the repo.
  Flake-based targets pass `?submodules=1`, so the `secrets/` submodule is
  expected to be populated locally.
