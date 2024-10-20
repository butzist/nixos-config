# Inspired by https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/6
args @ {
  inputs,
  lib,
  ...
}: let
  mkHome = username: hostname: (
    let
      inherit (args.systemConfigs."${hostname}") pkgs;
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules =
          args.extraModules
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
  mkNixosUser = hostname: username: {
    imports =
      args.extraImports
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
  };
  mkNixos = hostname: (
    let
      system = import (./. + "/machines/${hostname}/system.nix");
      config = import (./. + "/machines/${hostname}/configuration.nix");
      userConfigs =
        builtins.attrNames
        (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
      userHasConfig = user: builtins.elem "${user}.nix" userConfigs;
      # preview nixos config for host
      hostUsers = (config {pkgs = builtins.getAttr system inputs.nixpkgs.legacyPackages;}).users.users;
      hmUsers = builtins.filter userHasConfig (builtins.attrNames hostUsers);
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          args.extraModules
          ++ [
            inputs.home-manager.nixosModules.home-manager
            (./. + "/machines/${hostname}/configuration.nix")
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = builtins.listToAttrs (map (user: {
                  name = user;
                  value = mkNixosUser hostname user;
                })
                hmUsers);
            }
          ];
      }
  );
in {
  /*
  getHMConfigs returns all <user>@<host> = <HMConfig> attributes according to the user lists in all machine configs
  That means: mkHome for each username@hostname that satisfies the following conditions
  - has a config file in ./home
  - occurs in <hostname>.config.users.users && isNormalUser in that set
  needs some hocus pocus to restructure ...
  */
  getHMConfigs = let
    userConfigs =
      builtins.attrNames
      (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
    userHasConfig = user: builtins.elem "${user}.nix" userConfigs;
    usersPerHost = builtins.mapAttrs (n: v: v.config.users.users) args.systemConfigs;
    hostUsers = host: builtins.attrNames (builtins.getAttr host usersPerHost);
    hmUsers = host: builtins.filter userHasConfig (hostUsers host);
  in
    builtins.listToAttrs (
      builtins.concatLists
      (map
        (
          host:
            map
            (user: {
              name = "${user}@${host}";
              value = mkHome user host;
            })
            (hmUsers host)
        )
        (builtins.attrNames usersPerHost))
    );
  /*
  getSystemConfigs returns all <host> = <nixosSystem> attributes according to the machine configs
  That means: mkNixos for each hostname that satisfies the following conditions
  - has a folder in ./machines
  */
  getNixosConfigs = let
    machineConfigs =
      builtins.attrNames
      (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./machines));
  in
    builtins.listToAttrs (map
      (host: {
        name = host;
        value = mkNixos host;
      })
      machineConfigs);
}
