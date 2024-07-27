{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    nixvim.url = "github:nix-community/nixvim/nixos-24.05";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    stylix,
    nixvim,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    overlay-unstable = final: _last: {
      unstable = import nixpkgs-unstable {
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
        inherit pkgs;
        modules = [
          ({...}: {
            nixpkgs.overlays = [overlay-unstable];
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
