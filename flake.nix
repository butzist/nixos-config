{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
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
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            nixpkgs.config.allowUnfree = true;
          })
          ./machines/nixos/configuration.nix
        ];
      };
    };
    homeConfigurations = {
      adam = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [ overlay-unstable ];
            nixpkgs.config.allowUnfree = true;
          })
          ./users/adam.nix
        ];
      };
    };
  };
}
