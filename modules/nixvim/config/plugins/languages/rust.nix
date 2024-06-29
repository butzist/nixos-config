{pkgs, ...}: {
  plugins = {
    lsp.servers.rust-analyzer = {
      enable = true;
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
