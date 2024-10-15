{
  lib,
  pkgs,
  ...
}: {
  plugins = {
    lsp.servers = {
      html = {enable = true;};
      ts_ls = {enable = true;};
      cssls = {enable = true;};
    };

    conform-nvim = {
      settings = {
        formatters_by_ft = {
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
    };

    lint = {
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
          cmd = "${lib.getExe pkgs.eslint_d}";
        };
      };
    };

    dap = {
      adapters.servers = {
        pwa-node = {
          host = "localhost";
          port = "\${port}";
          executable = {
            command = "node";
            args = [
              "${pkgs.vscode-js-debug}/lib/node_modules/js-debug/dist/src/dapDebugServer.js"
              "\${port}"
            ];
          };
        };
      };

      configurations = let
        nodeConfig = [
          {
            type = "pwa-node";
            request = "launch";
            name = "Launch file";
            program = "\${file}";
            cwd = "\${workspaceFolder}";
          }
          {
            type = "pwa-node";
            request = "launch";
            name = "Launch jest file";
            program = "node_modules/jest-cli/bin/jest.js";
            runtimeArgs = [
              "--experimental-vm-modules"
            ];
            args = [
              "\${fileBasename}"
              "--verbose"
              "-i"
              "--no-cache"
              "--config"
              "jest.config.js"
            ];
            cwd = "\${workspaceFolder}";
          }
        ];
      in {
        javascript = nodeConfig;
        typescript = nodeConfig;
      };
    };

    web-devicons = {
      enable = true;
    };
  };
}
