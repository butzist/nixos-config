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
    system = "x86_64-linux";
    overlay-nixpkgs = final: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      bleeding = import inputs.nixpkgs-bleeding {
        inherit system;
        config.allowUnfree = true;
      };
      basedpyright = prev.basedpyright.overrideAttrs {
        dontCheckForBrokenSymlinks = true;
      };
      lldb = prev.lldb.overrideAttrs {
        dontCheckForBrokenSymlinks = true;
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
          ({...}: {
            nixpkgs.overlays = [overlay-nixpkgs];
            nixpkgs.config.allowUnfree = true;
          })
          inputs.sops-nix.homeManagerModules.sops
          inputs.stylix.homeManagerModules.stylix
          inputs.nvf.homeManagerModules.nvf
        ];
      })
      .getHMConfigs;
  };
}
