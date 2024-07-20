{...}: {
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
  };
}
