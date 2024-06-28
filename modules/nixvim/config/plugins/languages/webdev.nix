{lib, pkgs, ...}: {
  plugins.lsp.servers = {
    html = {enable = true;};
    tsserver = {enable = true;};
    cssls = {enable = true;};
  };

  plugins.conform-nvim = {
    formattersByFt = {
      html = [
        [ "prettierd" "prettier" ]
      ];
      css = [
        [ "prettierd" "prettier" ]
      ];
      javascript = [
        [ "prettierd" "prettier" ]
      ];
      typescript = [
        [ "prettierd" "prettier" ]
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
