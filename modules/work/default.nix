{pkgs, ...}: {
  imports = [
    ./vscode.nix
  ];

  home.packages = with pkgs; [
    kubectl
    terraform
    terragrunt
    helm

    unstable.microsoft-edge

    fnm
  ];

  programs = {
    go = {
      goPath = "go";
      goPrivate = ["gitlab.com/datahow"];
    };

    k9s = {
      enable = true;
      package = pkgs.unstable.k9s;
    };

    poetry = {
      enable = true;
      settings = {
        virtualenvs.create = true;
        virtualenvs.in-project = true;
      };
    };
  };
}
