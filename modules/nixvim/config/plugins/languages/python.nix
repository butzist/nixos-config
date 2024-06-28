{lib, pkgs, ...}: {
  plugins.lsp.servers = {
    pyright = {enable = true;};
  };

  plugins.conform-nvim = {
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
}
