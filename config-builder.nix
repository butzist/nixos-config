# Inspired by https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/6
{
  inputs,
  systemConfigs,
  lib,
  extraModules,
  ...
}: let
  mkHome = username: hostname: (
    let
      inherit (systemConfigs."${hostname}") pkgs;
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules =
          extraModules
          ++ [
            (
              if builtins.pathExists (./. + "/machines/${hostname}/home.nix")
              then (./. + "/machines/${hostname}/home.nix")
              else {}
            )
            (
              if builtins.pathExists (./. + "/users/${username}.nix")
              then (./. + "/users/${username}.nix")
              else {}
            )
          ];
        extraSpecialArgs = {
          inherit inputs username hostname;
        };
      }
  );
in {
  /*
  getHMConfigs returns all <user>@<host> = <HMConfig> attributes according to the user lists in all machine configs
  That means: mkHome for each username@hostname that satisfies the following conditions
  - has a dir in ./home
  - occurs in <hostname>.config.users.users && isNormalUser in that set
  needs some hocus pocus to restructure ...
  */
  getHMConfigs = let
    hmusers =
      lib.attrsets.attrNames
      (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
    hostusers = builtins.mapAttrs (n: v: v.config.users.users) systemConfigs;
  in
    lib.attrsets.zipAttrsWith (n: v: builtins.elemAt v 0)
    (builtins.filter (i: i != {}) (lib.lists.flatten (map
      (host:
        map
        (user:
          if (builtins.elem "${user}.nix" hmusers)
          then {
            "${user}@${host}" = mkHome user host;
          }
          else {})
        (builtins.attrNames (builtins.getAttr host hostusers)))
      (builtins.attrNames hostusers))));
}
