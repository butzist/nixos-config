{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
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
    overlay-nixpkgs = final: _last: {
      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      bleeding = import inputs.nixpkgs-bleeding {
        inherit system;
        config.allowUnfree = true;
      };
    };
  in {
    nixosConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        extraModules = [
          ({...}: {
            nixpkgs.overlays = [overlay-nixpkgs];
            nixpkgs.config.allowUnfree = true;
          })
        ];
        extraImports = [
          inputs.stylix.homeManagerModules.stylix
          inputs.nixvim.homeManagerModules.nixvim
        ];
      })
      .getNixosConfigs;
    homeConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        systemConfigs = inputs.self.nixosConfigurations;
        extraModules = [
          ({...}: {
            nixpkgs.overlays = [overlay-nixpkgs];
            nixpkgs.config.allowUnfree = true;
          })
          inputs.stylix.homeManagerModules.stylix
          inputs.nixvim.homeManagerModules.nixvim
        ];
      })
      .getHMConfigs;
  };
}
