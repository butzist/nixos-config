{
  plugins = {
    lsp.servers.rust-analyzer = {
      enable = false;
      installCargo = false;
      installRustc = false;
    };

    rustaceanvim = {
      enable = true;
      settings = {
        dap = {
          autoload_configurations = true;
        };
        tools = {
          enable_clippy = true;
        };
      };
    };

    crates-nvim = {
      enable = true;
    };
  };
}
