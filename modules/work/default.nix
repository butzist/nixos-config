{pkgs, ...}: {
  imports = [
    ./vscode.nix
    ./k9s.nix
  ];

  home.packages = with pkgs; [
    kubectl
    terraform
    terragrunt
    helm
    (azure-cli.withExtensions [])

    unstable.microsoft-edge

    fnm
  ];

  programs = {
    go = {
      goPath = "go";
      goPrivate = ["gitlab.com/datahow"];
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
