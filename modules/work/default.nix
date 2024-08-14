{pkgs, ...}: {
  imports = [
    ./vscode.nix
    ./k9s.nix
  ];

  home.packages = with pkgs; [
    unstable.microsoft-edge

    # devops
    kubectl
    terraform
    terragrunt
    helm
    (azure-cli.withExtensions [])

    # devops docs
    pre-commit
    helm-docs

    # http testing
    bombardier
    slowhttptest

    # language tools
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
