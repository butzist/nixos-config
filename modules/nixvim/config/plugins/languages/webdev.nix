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

  plugins.lint = {
    lintersByFt = {
      html = [
        "eslint_d"
      ];
      css = [
        "eslint_d"
      ];
      javascript = [
        "eslint_d"
      ];
      typescript = [
        "eslint_d"
      ];
      vue = [
        "eslint_d"
      ];
    };

    linters = {
      eslint_d = {
        command = "${lib.getExe pkgs.eslint_d}";
      };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    nvim-web-devicons
  ];
}
