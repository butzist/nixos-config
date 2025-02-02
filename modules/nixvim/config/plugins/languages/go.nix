{pkgs, ...}: {
  plugins = {
    lsp.servers.gopls = {enable = true;};

    dap-go = {
      enable = true;
      settings = {
        delve.path = "${pkgs.delve}/bin/dlv-dap";
      };
    };
  };
}
