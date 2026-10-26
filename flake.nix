{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="];
  };

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

    freetoken.url = "github:butzist/nix-freetoken/fix/noexec-jit-cache";

    # Generic jail/env/Herdr plumbing for preconfigured agents (no agent
    # wrappers or defaults): https://github.com/butzist/agent-toolbox
    agent-toolbox.url = "github:butzist/agent-toolbox";

    # Agent CLIs (rtk, herdr, crush, pi, ...) and their binary cache.
    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  outputs = inputs @ {
    flake-parts,
    ez-configs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        ez-configs.flakeModule
      ];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [
              alejandra
              deadnix
              jq
              nix-diff
              nix-output-monitor
              nix-tree
              nix-update
              nixd
              statix
            ]
            ++ [
              inputs.agenix.packages.${system}.default
            ];
        };

        formatter = pkgs.alejandra;
      };

      ezConfigs = {
        root = ./.;
        globalArgs = {inherit inputs;};

        nixos.hosts = {
          daddeln.userHomeModules = ["games" "adam"];
          hp-laptop.userHomeModules = ["adam" "games" "mirj"];
          legion.userHomeModules = ["work"];
          nuc.userHomeModules = ["work" "games" "adam"];
        };
      };

      flake.description = "NixOS configuration";
    };
}
