# One place where tack sources are turned into the `sources` module argument.
# `tack` is the raw resolver; `sources` adds nixpkgs aliases and local packages.
# Underscored aliases keep `with pkgs; [ _stable.foo ]` working without
# colliding with derivation arguments named after channels.
{
  pkgs,
  tack,
  ...
}: let
  pkgsFor = name:
    import tack.${name} {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

  overlays = [
    (final: _prev: {
      _bleeding = pkgsFor "nixpkgs-bleeding";
      _security = pkgsFor "nixpkgs-security";
      _stable = pkgsFor "nixpkgs-stable";
      _unstable = final;
    })
    tack.agenix.overlays.default
    tack.agent-toolbox.overlays.default
  ];
in {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = overlays;

  _module.args.sources =
    tack
    // {
      pkgs = pkgs;
      _bleeding = pkgs._bleeding;
      _security = pkgs._security;
      _stable = pkgs._stable;
      _unstable = pkgs;
      customPkgs = import ../packages {inherit pkgs;};
    };
}
