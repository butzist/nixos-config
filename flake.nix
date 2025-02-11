{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {nixpkgs, ...}: let
    overlay-nixpkgs = _final: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (prev) system;
        config.allowUnfree = true;
      };
      bleeding = import inputs.nixpkgs-bleeding {
        inherit (prev) system;
        config.allowUnfree = true;
      };
    };
    extra-nixpkgs = {...}: {
      imports = [./overlays/default.nix];

      nixpkgs.overlays = [overlay-nixpkgs];
      nixpkgs.config.allowUnfree = true;
    };
  in {
    nixosConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        extraModules = [extra-nixpkgs];
        extraImports = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeManagerModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getNixosConfigs;
    homeConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        systemConfigs = inputs.self.nixosConfigurations;
        extraModules = [
          extra-nixpkgs
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeManagerModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getHMConfigs;
  };
}
