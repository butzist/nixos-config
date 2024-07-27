{
  lib,
  pkgs,
  ...
}: {
  plugins = {
    lsp.servers = {
      pyright = {enable = true;};
    };

    conform-nvim = {
      formattersByFt = {
        python = [
          "black"
          "isort"
        ];
      };

      formatters = {
        black = {
          command = "${lib.getExe pkgs.black}";
        };
        isort = {
          command = "${lib.getExe pkgs.isort}";
        };
      };
    };

    lint = {
      lintersByFt = {
        python = ["ruff"];
      };

      linters = {
        ruff = {
          cmd = "${lib.getExe pkgs.ruff}";
        };
      };
    };

    dap.extensions.dap-python = {
      enable = true;
    };
  };
}
