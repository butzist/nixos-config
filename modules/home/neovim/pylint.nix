{
  pkgs,
  inputs,
  ...
}: let
  inherit (inputs.nvf.lib.nvim.languages) diagnosticsToLua;

  diagnosticsProviders = {
    pylint = {
      package = pkgs.pylint;
      nullConfig = _: ''
        table.insert(
          ls_sources,
          null_ls.builtins.diagnostics.pylint.with({
            command = "pylint",
            extra_args = {"--disable", "R"}
          })
        )
      '';
    };
  };
in {
  programs.nvf = {
    settings.vim = {
      lsp = {
        null-ls.enable = true;
        null-ls.sources = diagnosticsToLua {
          lang = "python";
          config = ["pylint"];
          inherit diagnosticsProviders;
        };
      };
    };
  };
}
