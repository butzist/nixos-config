{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding.url = "github:nixos/nixpkgs/master";
    nixpkgs-security.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "github:DeterminateSystems/determinate";
    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {nixpkgs, ...}: let
    overlay-nixpkgs = _final: prev: {
      bleeding = import inputs.nixpkgs-bleeding {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      security = import inputs.nixpkgs-security {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    };
    extra-nixpkgs = {...}: {
      imports = [./overlays];

      nixpkgs.overlays = [
        overlay-nixpkgs
        inputs.agenix.overlays.default
      ];
      nixpkgs.config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        extraModules = [extra-nixpkgs];
        extraImports = [
          inputs.agenix.homeManagerModules.default
          inputs.stylix.homeModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getNixosConfigs;
    darwinConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        extraModules = [extra-nixpkgs];
        extraImports = [
          inputs.agenix.homeManagerModules.default
          inputs.stylix.homeModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getDarwinConfigs;
    homeConfigurations =
      (import ./config-builder.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
        systemConfigs = inputs.self.nixosConfigurations;
        extraModules = [
          extra-nixpkgs
          inputs.agenix.homeManagerModules.default
          inputs.stylix.homeModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getHMConfigs;
  };
}
