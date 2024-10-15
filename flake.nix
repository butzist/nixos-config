{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    stylix.url = "github:danth/stylix";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = {
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    stylix,
    nixvim,
    ...
  }: let
    system = "x86_64-linux";
    overlay-stable = final: _last: {
      stable = import nixpkgs-stable {
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
          ./machines/nuc/configuration.nix
          home-manager.nixosModules.home-manager
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
    };
    homeConfigurations = {
      adam = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ({...}: {
            nixpkgs.overlays = [overlay-stable];
            nixpkgs.config.allowUnfree = true;
          })
          stylix.homeManagerModules.stylix
          nixvim.homeManagerModules.nixvim
          ./users/adam.nix
        ];
      };
    };
  };
}
