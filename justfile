# Bare `just` switches the current platform: NixOS on Linux, nix-darwin on macOS.
default: switch

# Rebuild and switch NixOS (Linux).
[linux]
switch:
    sudo nixos-rebuild switch --show-trace --flake '.?submodules=1'

# Rebuild and switch nix-darwin (macOS).
[macos]
switch:
    sudo darwin-rebuild --flake '.?submodules=1' switch

# Build the current platform's system generation without switching.
[linux]
build:
    nixos-rebuild build --show-trace --flake '.?submodules=1'

[macos]
build:
    darwin-rebuild build --flake '.?submodules=1'

# Install/sign UKIs and regenerate the pcrlock policy without switching.
[linux]
boot:
    sudo nixos-rebuild boot --show-trace --flake '.?submodules=1'

# Enroll keys or TPM2 disk unlock: `just enroll keys` or `just enroll disk`.
enroll target:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ target }}" in
      keys)
        sudo sbctl enroll-keys --microsoft
        ;;
      disk)
        sudo secure-boot-enroll
        ;;
      *)
        echo "Unknown enroll target '{{ target }}' (expected 'keys' or 'disk')." >&2
        exit 1
        ;;
    esac

# Switch the home-manager configuration.
home:
    home-manager switch --flake '.?submodules=1'

# Bootstrap a tool: `just install nix` or `just install hm`.
install target:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ target }}" in
      nix)
        curl -fsSL https://install.determinate.systems/nix | sh -s -- install
        ;;
      hm)
        nix shell 'nixpkgs#home-manager' --command home-manager switch --flake '.?submodules=1'
        ;;
      *)
        echo "Unknown install target '{{ target }}' (expected 'nix' or 'hm')." >&2
        exit 1
        ;;
    esac

# Add a tack patch: `just patch-add nixpkgs https://github.com/owner/repo/pull/123`.
patch-add name source:
    nix --extra-experimental-features 'nix-command flakes' develop '.?submodules=1' --command tack patch add "{{ name }}" "{{ source }}"

# Update tack pins (flake.lock is only a no-input stub).
update:
    nix --extra-experimental-features 'nix-command flakes' develop '.?submodules=1' --command tack update

# Pull, tack-update pins, rebuild this host, and commit the tack changes.
update-apply:
    #!/usr/bin/env bash
    set -euo pipefail
    git pull --rebase
    just update
    just
    git add .tack
    git commit -m "chore: update"

# Check the flake.
check:
    nix flake check '.?submodules=1'

# Report deferred-upgrade warnings without rebuilding.
todos:
    nix --extra-experimental-features 'nix-command flakes' eval --impure '.?submodules=1#nixosConfigurations' --apply 'import ./todos/show.nix null' --raw

# Report one watcher: `just todo nixpkgs-tack`.
todo name:
    nix --extra-experimental-features 'nix-command flakes' eval --impure '.?submodules=1#nixosConfigurations' --apply 'import ./todos/show.nix "{{ name }}"' --raw

# Format Nix files and the justfile.
fmt:
    nix fmt
    just --fmt

# Expire old home-manager generations and collect garbage.
gc:
    home-manager expire-generations "0 days" || true
    sudo nix-collect-garbage -d
    nix-collect-garbage -d
