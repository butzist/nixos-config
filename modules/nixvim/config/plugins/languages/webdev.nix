{
  lib,
  pkgs,
  ...
}: {
  plugins.lsp.servers = {
    html = {enable = true;};
    tsserver = {enable = true;};
    cssls = {enable = true;};
  };

  plugins.conform-nvim = {
    formattersByFt = {
      html = [
        ["prettierd" "prettier"]
      ];
      css = [
        ["prettierd" "prettier"]
      ];
      javascript = [
        ["eslint" "prettierd" "prettier"]
      ];
      typescript = [
        ["eslint" "prettierd" "prettier"]
      ];
      vue = [
        ["eslint" "prettierd" "prettier"]
      ];
    };

    formatters = {
      prettierd = {
        command = "${lib.getExe pkgs.prettierd}";
      };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    nvim-web-devicons
  ];
}
