{pkgs, ...}: {
  plugins = {
    lsp.servers.rust-analyzer = {
      enable = false;
      installCargo = false;
      installRustc = false;
    };

    rustaceanvim = {
      enable = true;
    };

    crates-nvim = {
      enable = true;
    };

    dap = {
      adapters.servers = {
        lldb = {
          host = "localhost";
          port = "\${port}";
          executable = {
            command = "${pkgs.unstable.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
            args = ["--port" "\${port}"];
          };
        };
      };

      configurations = {
        rust = [
          {
            name = "Launch";
            type = "lldb";
            request = "launch";
            cargo = {
              args = ["build"];
            };
          }
          {
            name = "Launch tests";
            type = "lldb";
            request = "launch";
            cargo = {
              args = ["test" "--no-run" "--lib"];
            };
          }
          {
            name = "Launch (choose file)";
            type = "lldb";
            request = "launch";
            program = {
              __raw = ''
                function()
                  return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end
              '';
            };
            cwd = "\${workspaceFolder}";
            stopOnEntry = false;
            args = [];
          }
        ];
      };
    };
  };
}
