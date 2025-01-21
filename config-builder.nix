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
          inherit inputs hostname;
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
      # preview nixos config for host
      hostUsers = (config {pkgs = builtins.getAttr system inputs.nixpkgs.legacyPackages;}).users.users;
      userConfigs =
        builtins.attrNames
        (lib.filterAttrs (n: v: v == "regular") (builtins.readDir ./users));
      userHasConfig = user: builtins.elem "${user}.nix" userConfigs;
      hmUsers = builtins.filter userHasConfig (builtins.attrNames hostUsers);
      secrets = builtins.listToAttrs (lib.flatten (map (user: let
        sshYaml = ./secrets/users/${user}/ssh.yaml;
      in
        if builtins.pathExists sshYaml
        then [
          {
            name = "users/${user}/ssh.yaml/private";
            value = {
              sopsFile = sshYaml;
              key = "private";
              mode = "0400";
              owner = "${user}";
              path = "/home/${user}/.ssh/id_ed25519";
            };
          }
          {
            name = "users/${user}/ssh.yaml/public";
            value = {
              sopsFile = sshYaml;
              key = "public";
              mode = "0444";
              owner = "${user}";
              path = "/home/${user}/.ssh/id_ed25519.pub";
            };
          }
        ]
        else [])
      (builtins.attrNames hostUsers)));
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          args.extraModules
          ++ [
            inputs.home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
            (./. + "/machines/${hostname}/configuration.nix")
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit inputs hostname;
              };
              home-manager.users = builtins.listToAttrs (map (user: {
                  name = user;
                  value = mkNixosUser hostname user;
                })
                hmUsers);
              sops.secrets = secrets;
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
