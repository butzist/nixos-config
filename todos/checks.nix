# Pure, warning-only deferred upgrades. Conditions must be derivable from
# pinned sources or local repo state: nixos-rebuild evaluates them in pure mode,
# so live network probing does not belong here.
{
  lib,
  pkgs,
  ...
}: let
  pins = builtins.readFile ../.tack/pins.toml;

  tackVersion = pkgs.tack.version or "0";
  tackPin = lib.hasInfix "[inputs.tack]" pins;
  tackPatchReady = lib.versionAtLeast tackVersion "2.0.0" && tackPin;
in [
  {
    name = "nixpkgs-tack";
    when = tackPatchReady;
    message = ''
      TODO(nixpkgs-tack): nixpkgs tack ${tackVersion} can replace the pinned tack.
      Drop [inputs.tack] from .tack/pins.toml, use pkgs.tack in flake.nix, then run tack update.
    '';
  }
]
