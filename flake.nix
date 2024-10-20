{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    stylix.url = "github:danth/stylix";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    stylix,
    nixvim,
    ...
  }: let
    system = "x86_64-linux";
    overlay-stable = final: _last: {
      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      nuc = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({...}: {
            nixpkgs.config.allowUnfree = true;
          })
          home-manager.nixosModules.home-manager
          ./machines/nuc/configuration.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.games = {...}: {
              imports = [
                stylix.homeManagerModules.stylix
                ./users/games.nix
              ];
            };
          }
        ];
      };

      thinkpad = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [];
      };
    };
    homeConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        systemConfigs = inputs.self.nixosConfigurations;
        extraModules = [
          ({...}: {
            nixpkgs.overlays = [overlay-stable];
            nixpkgs.config.allowUnfree = true;
          })
          inputs.stylix.homeManagerModules.stylix
          inputs.nixvim.homeManagerModules.nixvim
        ];
      })
      .getHMConfigs;
  };
}
