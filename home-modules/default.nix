{
  config,
  tack,
  lib,
  ...
}: let
  sensitiveFile = ../secrets/users/${config.home.username}/sensitive.nix;
in {
  imports = [
    ../shared-modules/sources.nix
    tack.agenix.homeManagerModules.default
    tack.nvf.homeModules.nvf
    tack.stylix.homeModules.stylix
  ];

  options.sensitive = lib.mkOption {
    description = "Sensitive per-user settings imported from the secrets submodule when present.";
    type = lib.types.attrs;
    default = {};
  };

  config.sensitive =
    lib.mkIf (builtins.pathExists sensitiveFile) (import sensitiveFile);
}
