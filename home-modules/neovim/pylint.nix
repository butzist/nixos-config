{
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames mapAttrs;
  inherit (lib.meta) getExe;

  diagnosticsProviders = {
    pylint = {
      package = pkgs.pylint;
    };
  };
in {
  programs.nvf = {
    settings.vim = {
      diagnostics.nvim-lint = {
        enable = true;
        linters_by_ft.python = attrNames diagnosticsProviders;
        linters =
          mapAttrs (_: value: {
            cmd = getExe value.package;
          })
          diagnosticsProviders;
      };
    };
  };
}
