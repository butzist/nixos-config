{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-bleeding.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    nixpkgs-msedge.url = "github:Daholli/nixpkgs/reinit-msedge";
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
      msedge = import inputs.nixpkgs-msedge {
        inherit (prev) system;
        config.allowUnfree = true;
      };
    };
    extra-nixpkgs = {...}: {
      imports = [./overlays];

      nixpkgs.overlays = [
        overlay-nixpkgs
        inputs.agenix.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;
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
          inputs.mac-app-util.homeManagerModules.default
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
          inputs.mac-app-util.homeManagerModules.default
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
          inputs.mac-app-util.homeManagerModules.default
        ];
      })
      .getHMConfigs;
  };
}
