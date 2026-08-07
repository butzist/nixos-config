{
  config,
  inputs,
  lib,
  ...
}: let
  sensitiveFile = ../secrets/users/${config.home.username}/sensitive.nix;
in {
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.nvf.homeManagerModules.nvf
    inputs.stylix.homeModules.stylix
    ../overlays
  ];

  options.sensitive = lib.mkOption {
    description = "Sensitive per-user settings imported from the secrets submodule when present.";
    type = lib.types.attrs;
    default = {};
  };

  config.sensitive =
    lib.mkIf (builtins.pathExists sensitiveFile) (import sensitiveFile);
}
