{
  description = "NixOS configuration";

  # Caches are declared here once: Nix reads nixConfig only from the top-level
  # flake
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://cache.manic.systems"
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # No native flake inputs: .tack resolves every source. The raw resolver
  # result is passed to modules as `tack`; shared-modules/sources.nix derives
  # the ergonomic `sources` namespace from it.
  outputs = args: let
    tack = (import ./.tack) {
      overrides = args.tackOverrides or {};
    };
    # flake-parts needs the real output args (self, tackOverrides, ...) as
    # well as tack's pins, so pass the union rather than only self.inputs.
    inputs = args // tack;
  in
    tack.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        tack.ez-configs.flakeModule
      ];

      # The root flake has no native inputs, so flake-parts cannot derive
      # `pkgs` from self.inputs; provide it from tack's nixpkgs pin instead.
      perSystem = {system, ...}: let
        pkgs = tack.nixpkgs.legacyPackages.${system};
      in {
        _module.args.pkgs = pkgs;

        devShells.default = pkgs.mkShell {
          packages =
            (with pkgs; [
              alejandra
              curl
              deadnix
              jq
              just
              mcp-nixos
              nix-diff
              nix-output-monitor
              nix-tree
              nix-update
              nixd
              statix
              sbctl
            ])
            ++ [
              tack.agenix.packages.${system}.default
              tack.tack.packages.${system}.default
            ];
        };

        formatter = pkgs.alejandra;

        # Committed stub of the private secrets/ submodule, mounted over it by
        # the agent jail (see .envrc). Nothing in it is a usable credential.
        packages.fake-secrets = import ./home-modules/development/agents/fake-secrets.nix {inherit pkgs;};
      };

      ezConfigs = {
        root = ./.;
        # Modules get the raw resolver as `tack`; shared-modules/sources.nix
        # derives `sources` with allowUnfree package-set aliases, external
        # overlays and ./packages as `sources.customPkgs`.
        globalArgs = {inherit tack;};
        earlyModuleArgs = {inherit tack;};

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
