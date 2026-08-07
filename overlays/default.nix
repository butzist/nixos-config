{
  inputs,
  ...
}: {
  imports = [
    ./build-fixes.nix
  ];

  # shared nixpkgs setup, applied to both NixOS and home-manager configs
  nixpkgs.overlays = [
    (final: prev: {
      _bleeding = import inputs.nixpkgs-bleeding {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      _security = import inputs.nixpkgs-security {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      _stable = import inputs.nixpkgs-stable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    })
    inputs.agenix.overlays.default
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };
}
