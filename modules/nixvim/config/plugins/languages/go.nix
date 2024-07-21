{pkgs, ...}: {
  plugins = {
    lsp.servers.gopls = {enable = true;};

    dap.extensions.dap-go = {
      enable = true;
      delve.path = "${pkgs.delve}/bin/dlv-dap";
    };
  };
}
