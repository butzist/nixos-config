# Inspired by https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/6
args @ {
  inputs,
  lib,
  ...
}: let
  mkHome = username: hostname: (
    let
      inherit (args.systemConfigs."${hostname}") pkgs;
      sshPublicKey = ./secrets/users/${username}/id_ed25519.pub;
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
            (
              if (builtins.pathExists sshPublicKey)
              then {
                home.file.".ssh/id_ed25519.pub".source = sshPublicKey;
              }
              else {}
            )
          ];
        extraSpecialArgs = {
          inherit inputs hostname;
          isDarwin = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
        };
      }
  );
  mkUser = hostname: username: let
    sshPublicKey = ./secrets/users/${username}/id_ed25519.pub;
  in {
    imports =
      args.extraImports
      ++ args.extraModules
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
        (
          if (builtins.pathExists sshPublicKey)
          then {
            home.file.".ssh/id_ed25519.pub".source = sshPublicKey;
          }
          else {}
        )
      ];
  };
  mkNixos = hostname: (
    let
      system = import (./. + "/machines/${hostname}/system.nix");
      config = import (./. + "/machines/${hostname}/configuration.nix");
      # preview nixos config for host
      hostUsers = (config {pkgs = builtins.getAttr system inputs.nixpkgs.legacyPackages;}).users.users;
      userConfigs =
        builtins.attrNames
        (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
      userHasConfig = user: builtins.elem "${user}.nix" userConfigs;
      hmUsers = builtins.filter userHasConfig (builtins.attrNames hostUsers);
      sshKeys = map (user: let
        sshPrivateKey = ./secrets/users/${user}/id_ed25519.age;
      in
        if (builtins.pathExists sshPrivateKey)
        then {
          age.secrets."users/${user}/id_ed25519" = {
            file = sshPrivateKey;
            mode = "0400";
            owner = "${user}";
            path = "/home/${user}/.ssh/id_ed25519";
          };
        }
        else {})
      (builtins.attrNames hostUsers);
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          args.extraModules
          ++ sshKeys
          ++ [
            inputs.home-manager.nixosModules.home-manager
            inputs.agenix.nixosModules.default
            inputs.stylix.nixosModules.stylix
            (./. + "/machines/${hostname}/configuration.nix")
            {
              home-manager = {
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs hostname;
                  isDarwin = system == "aarch64-darwin";
                };
                users = builtins.listToAttrs (map (user: {
                    name = user;
                    value = mkUser hostname user;
                  })
                  hmUsers);
              };
            }
          ];
        specialArgs = {
          inherit inputs hostname;
          isDarwin = system == "aarch64-darwin";
        };
      }
  );
  mkDarwin = hostname: (
    let
      system = import (./. + "/machines/${hostname}/system.nix");
      config = import (./. + "/machines/${hostname}/darwin-configuration.nix");
      # preview nixos config for host
      hostUsers = (config {pkgs = builtins.getAttr system inputs.nixpkgs.legacyPackages;}).users.users;
      userConfigs =
        builtins.attrNames
        (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
      userHasConfig = user: builtins.elem "${user}.nix" userConfigs;
      hmUsers = builtins.filter userHasConfig (builtins.attrNames hostUsers);
      sshKeys = map (user: let
        sshPrivateKey = ./secrets/users/${user}/id_ed25519.age;
      in
        if (builtins.pathExists sshPrivateKey)
        then {
          age.secrets."users/${user}/id_ed25519" = {
            file = sshPrivateKey;
            mode = "0400";
            owner = "${user}";
            path = "/Users/${user}/.ssh/id_ed25519";
          };
        }
        else {})
      (builtins.attrNames hostUsers);
    in
      inputs.nix-darwin.lib.darwinSystem {
        modules =
          args.extraModules
          ++ sshKeys
          ++ [
            inputs.home-manager.darwinModules.home-manager
            inputs.agenix.darwinModules.default
            inputs.determinate.darwinModules.default

            (./. + "/machines/${hostname}/darwin-configuration.nix")
            {
              home-manager = {
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs hostname;
                  isDarwin = system == "aarch64-darwin";
                };
                users = builtins.listToAttrs (map (user: {
                    name = user;
                    value = mkUser hostname user;
                  })
                  hmUsers);
              };
              nix.enable = false; # nix is managed by determinate
            }
          ];
        specialArgs = {
          inherit inputs hostname;
          isDarwin = system == "aarch64-darwin";
        };
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
  getNixosConfigs returns all <host> = <nixosSystem> attributes according to the machine configs
  That means: mkNixos for each hostname that satisfies the following conditions
  - has a folder in ./machines
  - folder contains configuration.nix file
  */
  getNixosConfigs = let
    machines =
      builtins.attrNames
      (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./machines));
    machineConfigs = lib.filter (hostname: builtins.pathExists (./. + "/machines/${hostname}/configuration.nix")) machines;
  in
    builtins.listToAttrs (map
      (host: {
        name = host;
        value = mkNixos host;
      })
      machineConfigs);
  /*
  getDarwinConfigs returns all <host> = <darwinSystem> attributes according to the machine configs
  That means: mkDarwin for each hostname that satisfies the following conditions
  - has a folder in ./machines
  - folder contains darwin-configuration.nix file
  */
  getDarwinConfigs = let
    machines =
      builtins.attrNames
      (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./machines));
    machineConfigs = lib.filter (hostname: builtins.pathExists (./. + "/machines/${hostname}/darwin-configuration.nix")) machines;
  in
    builtins.listToAttrs (map
      (host: {
        name = host;
        value = mkDarwin host;
      })
      machineConfigs);
}
